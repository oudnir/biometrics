import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');
  runApp(const MyApp());
}

// ---------------- APP ----------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showLanding = true;
  double dataAllocation = 0.0;
  bool isDark = true;
  bool _loaderOpen = false;
  String secretKey =
      "xnd_development_oq9wRO2BbI4TFJ40nNjBFNaWaBC7cepjUgNjCs9xm0E5FM55fTF3Jy81UC6NGxz0";

  // Function to toggle theme from child widgets
  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      home: const AppRouter(),
    );
  }

  Widget buildLandingPage(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.creditcard_fill,
              size: 100,
              color: CupertinoColors.activeBlue,
            ),
            const SizedBox(height: 20),
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

// ---------------- APP ROUTER ----------------
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final box = Hive.box('database');

  @override
  Widget build(BuildContext context) {
    final username = box.get("username");

    if (username == null || username.toString().isEmpty) {
      // No account exists, show create account
      return const CreateAccountPage();
    } else {
      // Account exists, check if logged in
      final isLoggedIn = box.get("isLoggedIn", defaultValue: false);

      if (!isLoggedIn) {
        // Not logged in, show login page
        return LoginPage(
          onLoginSuccess: () {
            // Update login state in Hive
            box.put("isLoggedIn", true);

            // Force rebuild of AppRouter
            setState(() {});
          },
        );
      } else {
        // Logged in, show main app
        return MainApp(
          dataAllocation: 0.0,
          isDark: true,
          onThemeChanged: () {},
          secretKey: "xnd_development_oq9wRO2BbI4TFJ40nNjBFNaWaBC7cepjUgNjCs9xm0E5FM55fTF3Jy81UC6NGxz0",
          loaderOpen: false,
          onLogout: () {
            // Update login state in Hive
            box.put("isLoggedIn", false);

            // Force rebuild of AppRouter
            setState(() {});
          },
        );
      }
    }
  }
}

// ---------------- FULL APP ----------------
class MainApp extends StatefulWidget {
  final double dataAllocation;
  final bool isDark;
  final VoidCallback onThemeChanged;
  final String secretKey;
  final bool loaderOpen;
  final VoidCallback onLogout;

  const MainApp({
    super.key,
    required this.dataAllocation,
    required this.isDark,
    required this.onThemeChanged,
    required this.secretKey,
    required this.loaderOpen,
    required this.onLogout,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  double dataAllocation = 0.0;
  bool _loaderOpen = false;
  Timer? _paymentTimer;
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricsEnabled = false;
  bool biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    dataAllocation = widget.dataAllocation;
    _loaderOpen = widget.loaderOpen;
    _checkBiometricsAvailability();
    _loadBiometricsSetting();
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      setState(() {
        biometricsAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      print("Error checking biometrics availability: $e");
      setState(() {
        biometricsAvailable = false;
      });
    }
  }

  Future<void> _loadBiometricsSetting() async {
    try {
      final box = Hive.box('database');
      final savedBiometrics = box.get("biometricsEnabled", defaultValue: false);
      setState(() {
        biometricsEnabled = savedBiometrics;
      });
    } catch (e) {
      print("Error loading biometrics setting: $e");
    }
  }

  Future<void> toggleBiometrics() async {
    try {
      final box = Hive.box('database');

      if (!biometricsEnabled) {
        // Enable biometrics - first check if available
        if (!biometricsAvailable) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text("Biometrics Not Available"),
              content: const Text("Your device does not support biometrics or they are not set up."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
          return;
        }

        // Try to authenticate to enable biometrics
        try {
          final authenticated = await auth.authenticate(
            localizedReason: 'Authenticate to enable biometrics login',
          );

          if (authenticated) {
            setState(() {
              biometricsEnabled = true;
            });
            box.put("biometricsEnabled", true);

            // Show success message
            showCupertinoDialog(
              context: context,
              builder: (_) => const CupertinoAlertDialog(
                title: Text("Biometrics Enabled"),
                content: Text("Biometrics login has been enabled successfully."),
                actions: [
                  CupertinoDialogAction(
                    child: Text("OK"),
                    onPressed: null,
                  ),
                ],
              ),
            );
          } else {
            // Authentication failed or cancelled
            showCupertinoDialog(
              context: context,
              builder: (_) => const CupertinoAlertDialog(
                title: Text("Authentication Failed"),
                content: Text("Could not authenticate. Biometrics not enabled."),
                actions: [
                  CupertinoDialogAction(
                    child: Text("OK"),
                    onPressed: null,
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          print("Authentication error: $e");
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text("Authentication Error"),
              content: Text("Error: $e"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      } else {
        // Disable biometrics - show confirmation dialog
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Disable Biometrics"),
            content: const Text("Are you sure you want to disable biometrics login?"),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: const Text("Disable"),
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context); // Close confirmation dialog
                  setState(() {
                    biometricsEnabled = false;
                  });
                  box.put("biometricsEnabled", false);

                  // Show disabled message
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => const CupertinoAlertDialog(
                      title: Text("Biometrics Disabled"),
                      content: Text("Biometrics login has been disabled."),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("OK"),
                          onPressed: null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error toggling biometrics: $e");
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Error"),
          content: Text("An error occurred: $e"),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

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
                style: const TextStyle(
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
                style: const TextStyle(
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

  Widget headerCard() {
    final box = Hive.box('database');
    final username = box.get("username") ?? "User";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
          Text(
            "$username",
            style: const TextStyle(
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

        return CupertinoPageScaffold(
          child: SafeArea(
            child: ListView(
              children: [
                CupertinoListSection.insetGrouped(
                  children: [
                    // ---- DARK MODE ----
                    CupertinoListTile(
                      trailing: CupertinoSwitch(
                        value: widget.isDark,
                        onChanged: (value) {
                          widget.onThemeChanged();
                        },
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.moon_fill,
                            color: CupertinoColors.white, size: 20),
                      ),
                      title: const Text("Dark Mode"),
                    ),

                    // ---- BIOMETRICS ----
                    CupertinoListTile(
                      trailing: CupertinoSwitch(
                        value: biometricsEnabled,
                        onChanged: (value) async {
                          await toggleBiometrics();
                        },
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: biometricsAvailable
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.lock_shield_fill,
                            color: CupertinoColors.white, size: 20),
                      ),
                      title: const Text("Biometrics"),
                      subtitle: biometricsAvailable
                          ? const Text("Use fingerprint or face ID")
                          : const Text("Not available on this device"),
                    ),

                    // ---- ABOUT ----
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
                                  onPressed: () => Navigator.pop(context),
                                ),
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

                    // ---- SIGN OUT ----
                    CupertinoListTile(
                      trailing: const Icon(CupertinoIcons.arrow_right_circle_fill),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(
                          CupertinoIcons.square_arrow_right,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text("Sign Out"),
                      onTap: () async {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text("Sign Out"),
                            content: const Text("Are you sure you want to sign out?"),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              CupertinoDialogAction(
                                child: const Text("Sign Out"),
                                isDestructiveAction: true,
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  widget.onLogout(); // Call logout callback
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
      navigationBar: const CupertinoNavigationBar(middle: Text("Payment")),
      child: WebViewWidget(controller: controller!),
    );
  }
}

// ---------------- CREATE ACCOUNT PAGE ----------------
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final box = Hive.box('database');
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Create Account"),
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              CupertinoTextField(
                controller: _username,
                placeholder: "Username",
                padding: const EdgeInsets.symmetric(vertical: 16),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.person),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _password,
                placeholder: "Password",
                obscureText: _obscurePassword,
                padding: const EdgeInsets.symmetric(vertical: 16),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.lock),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 18),
              CupertinoButton.filled(
                onPressed: () {
                  final username = _username.text.trim();
                  final password = _password.text.trim();

                  if (username.isEmpty || password.isEmpty) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => const CupertinoAlertDialog(
                        title: Text("Error"),
                        content: Text("Please enter both username and password"),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("OK"),
                            onPressed: null,
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  box.put("username", username);
                  box.put("password", password);
                  box.put("isLoggedIn", false); // Set to not logged in initially
                  box.put("biometricsEnabled", false); // Default biometrics disabled

                  // Navigate to login page
                  Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const AppRouter(),
                    ),
                        (route) => false,
                  );
                },
                child: const Text("CREATE ACCOUNT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- LOGIN PAGE ----------------
class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;
  final box = Hive.box('database');
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricsAvailable = false;
  bool biometricsEnabled = false;
  bool checkingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      // Check if biometrics are available on the device
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      setState(() {
        biometricsAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
      });

      // Check if biometrics are enabled in app settings
      final savedBiometrics = box.get("biometricsEnabled", defaultValue: false);
      setState(() {
        biometricsEnabled = savedBiometrics && biometricsAvailable;
        checkingBiometrics = false;
      });

      // If biometrics are enabled and available, try to authenticate automatically after a delay
      if (biometricsEnabled && biometricsAvailable) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _authenticateWithBiometrics();
          }
        });
      }
    } catch (e) {
      print("Error checking biometrics: $e");
      setState(() {
        biometricsAvailable = false;
        biometricsEnabled = false;
        checkingBiometrics = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to login to GameVault',
      );

      if (authenticated) {
        // Get saved username and password
        final savedUsername = box.get("username") ?? "";
        final savedPassword = box.get("password") ?? "";

        // Auto-fill the form
        setState(() {
          _username.text = savedUsername;
          _password.text = savedPassword;
        });

        // Automatically login after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          _login();
        });
      }
    } catch (e) {
      print("Biometric authentication error: $e");
      // Don't show error dialog, just let user login manually
    }
  }

  void _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text("Error"),
          content: Text("Please enter both username and password"),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: null,
            ),
          ],
        ),
      );
      return;
    }

    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => loading = false);

    final savedUsername = box.get("username") ?? "";
    final savedPassword = box.get("password") ?? "";

    if (_username.text.trim() != savedUsername || _password.text != savedPassword) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Invalid Login"),
          content: const Text("Username or password is incorrect"),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // Successful login - call the callback
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Login",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to continue to GameVault",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 40),
              const Icon(
                CupertinoIcons.person_circle_fill,
                size: 110,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(height: 40),
              CupertinoTextField(
                controller: _username,
                placeholder: "Username",
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.username],
                padding: const EdgeInsets.symmetric(vertical: 16),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.person,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _password,
                placeholder: "Password",
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                padding: const EdgeInsets.symmetric(vertical: 16),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.lock,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                suffix: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 30),

              // Show loading indicator while checking biometrics
              if (checkingBiometrics)
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: CupertinoActivityIndicator(),
                ),

              // Biometrics Button (if available and enabled)
              if (!checkingBiometrics && biometricsAvailable && biometricsEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: CupertinoButton.filled(
                    onPressed: loading ? null : _authenticateWithBiometrics,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.lock_shield_fill, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "LOGIN WITH BIOMETRICS",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              CupertinoButton.filled(
                onPressed: loading ? null : _login,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(16),
                child: loading
                    ? const CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                )
                    : const Text(
                  "LOGIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              CupertinoButton.filled(
                color: CupertinoColors.systemRed,
                onPressed: loading
                    ? null
                    : () {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text("Erase Data"),
                      content: const Text(
                          "Are you sure you want to remove your saved account data?"),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          child: const Text("OK"),
                          onPressed: () {
                            box.delete("username");
                            box.delete("password");
                            box.delete("isLoggedIn");
                            box.delete("biometricsEnabled");
                            Navigator.pop(context);

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(
                                    builder: (_) => const AppRouter()),
                                    (route) => false,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(16),
                child: const Text(
                  "ERASE DATA",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
