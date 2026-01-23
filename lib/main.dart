import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() {

  runApp(const MyApp());
}

// ---------------- APP ----------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showLanding = true; // Show landing page first
  double dataAllocation = 0.0;
  bool isDark = true;
  bool _loaderOpen = false;

  // Payment
  String secretKey =
      "xnd_development_oq9wRO2BbI4TFJ40nNjBFNaWaBC7cepjUgNjCs9xm0E5FM55fTF3Jy81UC6NGxz0";

  Timer? _paymentTimer;

  @override
  void dispose() {
    _paymentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
    debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      home: showLanding
          ? buildLandingPage(context)
          : MainApp( // Your full app as a separate widget
        dataAllocation: dataAllocation,
        isDark: isDark,
        secretKey: secretKey,
        loaderOpen: _loaderOpen,
      ),
    );
  }

  // ---------------- Landing Page ----------------
  Widget buildLandingPage(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon - Vault Cube
            const Icon(
              CupertinoIcons.creditcard_fill, // <-- new epic icon
              size: 100,
              color: CupertinoColors.activeBlue,
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              "GameVault",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
                fontFamily: "SF Pro",
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Secure Payments, Instant Delivery",
              style: TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
                fontFamily: "SF Pro",
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Benefits Icons Row ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Column(
                    children: [
                      Icon(CupertinoIcons.lock_fill,
                          size: 30, color: CupertinoColors.activeBlue),
                      SizedBox(height: 6),
                      Text("Secure",
                          style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(CupertinoIcons.clock_fill,
                          size: 30, color: CupertinoColors.activeBlue),
                      SizedBox(height: 6),
                      Text("Fast",
                          style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(CupertinoIcons.person_2_fill,
                          size: 30, color: CupertinoColors.activeBlue),
                      SizedBox(height: 6),
                      Text("Support",
                          style: TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ---------------- Recharge Button ----------------
            GestureDetector(
              onTap: () {
                setState(() {
                  showLanding = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  "RECHARGE NOW",
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: "SF Pro",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- FULL APP ----------------
class MainApp extends StatefulWidget {
  final double dataAllocation;
  final bool isDark;
  final String secretKey;
  final bool loaderOpen;

  const MainApp(
      {super.key,
        required this.dataAllocation,
        required this.isDark,
        required this.secretKey,
        required this.loaderOpen});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  double dataAllocation = 0.0;
  bool isDark = true;
  bool _loaderOpen = false;
  Timer? _paymentTimer;

  @override
  void initState() {
    super.initState();
    dataAllocation = widget.dataAllocation;
    isDark = widget.isDark;
    _loaderOpen = widget.loaderOpen;
  }

  // ---------------- Payment Functions ----------------
  Future<void> payNow(BuildContext context, int price, double points) async {
    _loaderOpen = true;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text("Waiting for Payment Page"),
        content: SizedBox(
          height: 50,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ),
    );

    String auth = 'Basic ' + base64Encode(utf8.encode(widget.secretKey));
    final url = "https://api.xendit.co/v2/invoices/";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Authorization": auth, "Content-Type": "application/json"},
      body: jsonEncode({"external_id": "invoice_example", "amount": price}),
    );

    final data = jsonDecode(response.body);
    String id = data['id'];
    String invoiceUrl = data['invoice_url'];

    _paymentTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => PaymentPage(url: invoiceUrl)),
        );
      }
    });

    _checkPaymentStatus(auth, url, id, points);
  }

  void _checkPaymentStatus(String auth, String url, String id, double points) {
    _paymentTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final response =
        await http.get(Uri.parse(url + id), headers: {"Authorization": auth});
        final data = jsonDecode(response.body);

        if (data['status'] == "PAID") {
          timer.cancel();

          setState(() {
            dataAllocation += points;
          });

          if (_loaderOpen &&
              Navigator.of(navKey.currentContext!, rootNavigator: true).canPop()) {
            Navigator.of(navKey.currentContext!, rootNavigator: true).pop();
            _loaderOpen = false;
          }

          if (Navigator.canPop(navKey.currentContext!)) {
            Navigator.pop(navKey.currentContext!);
          }

          Future.microtask(() {
            if (navKey.currentContext != null) {
              showCupertinoDialog(
                context: navKey.currentContext!,
                builder: (_) => CupertinoAlertDialog(
                  title: const Text("Payment Successful"),
                  content: const Text("Your points have been added!"),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.pop(navKey.currentContext!);
                      },
                    ),
                  ],
                ),
              );
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _paymentTimer?.cancel();
    super.dispose();
  }

  // ---------------- GPoints Card ----------------
  Widget gpoints(BuildContext context, String price, String points, String name) {
    return GestureDetector(
      onTap: () => payNow(context, int.parse(price), double.parse(points)),
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$price PHP",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "+$points Points",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Buy",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CupertinoColors.systemBlue, CupertinoColors.activeBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shaun Homeboy",
            style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "IGN: Daiguren Hyorinmaru",
            style: TextStyle(color: CupertinoColors.systemGrey6),
          ),
          const SizedBox(height: 20),
          Text(
            dataAllocation.toStringAsFixed(1),
            style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold),
          ),
          const Text(
            "Game Credit Points",
            style: TextStyle(color: CupertinoColors.systemGrey6, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ---------------- UI Build ----------------
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: "Settings",
          ),
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 0) {
          // ---------------- Home Tab ----------------
          return CupertinoPageScaffold(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  headerCard(),
                  const SizedBox(height: 20),
                  const Text("Game Points Credits",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        gpoints(context, "100", "110", "G Points"),
                        gpoints(context, "200", "210", "G Points"),
                        gpoints(context, "500", "510", "G Points"),
                        gpoints(context, "499", "550", "G Points"),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        gpoints(context, "10", "11", "G Points"),
                        gpoints(context, "20", "22", "G Points"),
                        gpoints(context, "50", "55", "G Points"),
                        gpoints(context, "70", "75", "G Points"),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        gpoints(context, "99", "200", "G Points"),
                        gpoints(context, "199", "499", "G Points"),
                        gpoints(context, "299", "699", "G Points"),
                        gpoints(context, "399", "799", "G Points"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ---------------- Settings Tab ----------------
        return CupertinoPageScaffold(
          child: SafeArea(
            child: ListView(
              children: [
                CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      trailing: CupertinoSwitch(
                        value: isDark,
                        onChanged: (value) => setState(() => isDark = value),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child:
                        const Icon(CupertinoIcons.moon_fill, color: CupertinoColors.white, size: 20),
                      ),
                      title: const Text("Dark Mode"),
                    ),
                    GestureDetector(
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: const Text("Members"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text("Hipolito Earl Lawrence"),
                                  Text("Jimenez Mark Lenard"),
                                  Text("Marin Jay"),
                                  Text("Miranda James Patrick"),
                                  Text("Miranda Tayshaun"),
                                  Text("Narciso Amiel"),
                                  Text("Pontanilla Mark Angelo"),
                                  Text("Ruiz John Avy"),
                                ],
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Close"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            );
                          },
                        );
                      },
                      child: CupertinoListTile(
                        trailing: const Icon(CupertinoIcons.chevron_forward),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: CupertinoColors.systemPurple,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(
                            CupertinoIcons.info,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                        title: const Text("About"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- PAYMENT PAGE ----------------
class PaymentPage extends StatefulWidget {
  final String url;
  const PaymentPage({super.key, required this.url});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  WebViewController? controller;
  bool openingExternal = false;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows) {
      openingExternal = true;
      _openExternalBrowser();
    } else {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _openExternalBrowser() async {
    await launchUrl(Uri.parse(widget.url),
        mode: LaunchMode.externalApplication);
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (openingExternal || controller == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar:
      const CupertinoNavigationBar(middle: Text("Payment")),
      child: WebViewWidget(controller: controller!),
    );
  }
}
