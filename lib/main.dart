import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  bool isDark = true;

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
        primaryColor: const Color(0xFF5E5CE6), // soft purple accent
        scaffoldBackgroundColor:
        isDark ? const Color(0xFF0F0F10) : const Color(0xFFF5F5F7),
        textTheme: const CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      home: const AppRouter(),
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
      return const CreateAccountPage();
    }

    final isLoggedIn = box.get("isLoggedIn", defaultValue: false);
    if (!isLoggedIn) {
      return LoginPage(onLoginSuccess: () {
        box.put("isLoggedIn", true);
        setState(() {});
      });
    }

    return MainApp(
      isDark: CupertinoTheme.of(context).brightness == Brightness.dark,
      onThemeChanged: () => setState(() {}),
      onLogout: () {
        box.put("isLoggedIn", false);
        setState(() {});
      },
    );
  }
}

// ---------------- MAIN APP ----------------
class MainApp extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;
  final VoidCallback onLogout;

  const MainApp({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricsEnabled = false;
  bool biometricsAvailable = false;

  List<Map<String, dynamic>> todoList = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _checkBiometricsAvailability();
    _loadBiometricsSetting();
  }
  void _loadTasks() {
    final box = Hive.box('database');
    final savedTasks = box.get("tasks", defaultValue: []);

    todoList = List<Map<String, dynamic>>.from(
      (savedTasks as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }



  Future<void> _checkBiometricsAvailability() async {
    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();
      Hive.box('database').put("tasks", todoList);
      setState(() {
        biometricsAvailable = canCheckBiometrics && available.isNotEmpty;
      });
    } catch (e) {
      biometricsAvailable = false;
    }
  }

  Future<void> _loadBiometricsSetting() async {
    final box = Hive.box('database');
    final saved = box.get("biometricsEnabled", defaultValue: false);
    setState(() {
      biometricsEnabled = saved;
    });
  }

  Future<void> toggleBiometrics() async {
    final box = Hive.box('database');

    // Turn ON biometrics
    if (!biometricsEnabled) {
      if (!biometricsAvailable) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Biometrics Not Available"),
            content: const Text("Your device does not support biometrics."),
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

      try {
        final ok = await auth.authenticate(
          localizedReason: 'Authenticate to enable biometrics login',
        );
        if (ok) {
          setState(() => biometricsEnabled = true);
          box.put("biometricsEnabled", true);

          // Popup confirmation for enabling
          showCupertinoDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) {
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
              });
              return CupertinoPopupSurface(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Biometrics Enabled",
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      } catch (e) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }

      // Turn OFF biometrics
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Disable Biometrics"),
          content: const Text("Are you sure you want to disable biometrics?"),
          actions: [
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text("Disable"),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                setState(() => biometricsEnabled = false);
                box.put("biometricsEnabled", false);

                // Popup confirmation for disabling
                showCupertinoDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pop(context);
                    });
                    return CupertinoPopupSurface(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Biometrics Disabled",
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    }
  }

  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text("New Task"),
        message: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "Enter task name",
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Text("Add Task"),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  todoList.add({
                    "Task": controller.text,
                    "isDone": false,
                  });
                });
                Hive.box('database').put("tasks", todoList);
              }
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings), label: "Settings"),
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 0) {
          // Home Tab
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.add),
                onPressed: _showAddTaskDialog,
              ),
            ),
            child: SafeArea(
              child: todoList.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 52,
                      color: CupertinoColors.systemGrey2,

                      fontWeight: FontWeight.w500,

                    ),
                    SizedBox(height: 16),
                    Text(
                      "No Errands Today!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView(
                children: [
                  CupertinoListSection.insetGrouped(
                    header: const Text("To Do List"),
                    children: List.generate(todoList.length, (i) {
                      final item = todoList[i];
                      return Dismissible(
                        key: Key("${item["Task"]}$i"),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await showCupertinoDialog<bool>(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Delete Task"),
                              content: const Text(
                                  "Are you sure you want to delete this task?"),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Cancel"),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text("Delete"),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          setState(() {
                            todoList.removeAt(i);
                          });
                          Hive.box('database').put("tasks", todoList);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: CupertinoColors.systemRed,
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.white,
                          ),
                        ),
                        child: CupertinoListTile(
                          leading: GestureDetector(
                            onTap: () {
                              setState(() {
                                item["isDone"] = !item["isDone"];
                              });
                              Hive.box('database').put("tasks", todoList);
                            },
                            child: Icon(
                              item["isDone"]
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.circle,
                              color: item["isDone"]
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                          title: GestureDetector(
                            onLongPress: () async {
                              final shouldDelete = await showCupertinoDialog<
                                  bool>(
                                context: context,
                                builder: (_) => CupertinoAlertDialog(
                                  title: const Text("Delete Task"),
                                  content: const Text(
                                      "Are you sure you want to delete this task?"),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text("Cancel"),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text("Delete"),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete ?? false) {
                                setState(() {
                                  todoList.removeAt(i);
                                });
                                Hive.box('database').put("tasks", todoList);
                              }
                            },
                            child: Text(
                              item["Task"],
                              style: TextStyle(
                                decoration: item["isDone"]
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Settings Tab
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text("Settings"),
            ),
            child: SafeArea(
              child: ListView(
                children: [
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: const Text("Dark Mode"),
                        leading: const Icon(CupertinoIcons.moon_fill,
                            color: CupertinoColors.systemYellow),
                        trailing: CupertinoSwitch(
                          value: widget.isDark,
                          onChanged: (_) => widget.onThemeChanged(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text("Biometrics"),
                        subtitle: biometricsAvailable
                            ? const Text("Use fingerprint or face ID")
                            : const Text("Not available on this device"),
                        leading: const Icon(CupertinoIcons.lock_shield_fill,
                            color: CupertinoColors.systemGreen),
                        trailing: CupertinoSwitch(
                          value: biometricsEnabled,
                          onChanged: (_) => toggleBiometrics(),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text("About"),
                        leading: const Icon(CupertinoIcons.info_circle_fill,
                            color: CupertinoColors.systemPurple),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
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
                            ),
                          );
                        },
                      ),
                      CupertinoListTile(
                        title: const Text("Sign Out"),
                        leading: const Icon(CupertinoIcons.square_arrow_right,
                            color: CupertinoColors.systemRed),
                        trailing: const Icon(CupertinoIcons.chevron_left),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Sign Out"),
                              content: const Text(
                                  "Are you sure you want to sign out?"),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                CupertinoDialogAction(
                                  child: const Text("Sign Out"),
                                  isDestructiveAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onLogout();
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
        }
      },
    );
  }

}

// ---------------- CREATE ACCOUNT ----------------
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final box = Hive.box('database');
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool obscure = true;

  bool isValidPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$',
    );
    return regex.hasMatch(password);
  }


  Widget _input({
    required IconData icon,
    required String placeholder,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : CupertinoColors.white,

        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.systemGrey),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              obscureText: isPassword ? obscure : false,
              decoration: null,
              style: const TextStyle(color: CupertinoColors.white),
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => obscure = !obscure),
              child: Icon(
                obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: CupertinoColors.systemGrey,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0F0F10),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,

                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create an account to start your To do list",
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 32),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: const Color(0xFF5E5CE6),

                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              _input(
                icon: CupertinoIcons.person,
                placeholder: "Username",
                controller: username,
              ),
              const SizedBox(height: 16),
              _input(
                icon: CupertinoIcons.lock,
                placeholder: "Password",
                controller: password,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _input(
                icon: CupertinoIcons.lock_rotation,
                placeholder: "Confirm Password",
                controller: confirmPassword,
                isPassword: true,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF5E5CE6),

                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    if (username.text.isEmpty ||
                        password.text.isEmpty ||
                        confirmPassword.text.isEmpty) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text("Missing Fields"),
                          content: const Text("Please fill in all fields."),
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

                    if (password.text != confirmPassword.text) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text("Password Mismatch"),
                          content: const Text("Passwords do not match."),
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

                    if (!isValidPassword(password.text)) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text("Weak Password"),
                          content: const Text(
                            "Password must be at least 8 characters,\n"
                                "include 1 uppercase letter,\n"
                                "1 number, and 1 special symbol (!@#\$&*~).",
                          ),
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

                    box.put("username", username.text);
                    box.put("password", password.text);
                    box.put("isLoggedIn", false);
                    box.put("biometricsEnabled", false);
                    box.put("tasks", []);

                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (_) => const AppRouter()),
                    );
                  },



                  child: const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

// ---------------- LOGIN ----------------
class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final box = Hive.box('database');
  final LocalAuthentication auth = LocalAuthentication();

  bool biometricsAvailable = false;
  bool biometricsEnabled = false;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await auth.canCheckBiometrics;
    final available = await auth.getAvailableBiometrics();
    final enabled = box.get("biometricsEnabled", defaultValue: false);

    setState(() {
      biometricsAvailable = canCheck && available.isNotEmpty;
      biometricsEnabled = enabled && biometricsAvailable;
    });

    if (biometricsEnabled) {
      Future.delayed(const Duration(milliseconds: 600), _authenticateWithBiometrics);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final ok = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        biometricOnly: true,
      );
      if (ok) {
        username.text = box.get("username") ?? "";
        password.text = box.get("password") ?? "";
        _login();
      }
    } catch (_) {}
  }

  void _login() {
    final savedUsername = box.get("username");
    final savedPassword = box.get("password");

    if (username.text == savedUsername && password.text == savedPassword) {
      widget.onLoginSuccess();
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Invalid Login"),
          content: const Text("Username or password is incorrect."),
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

  Widget _input({
    required IconData icon,
    required String placeholder,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.darkColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.systemGrey),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              obscureText: isPassword ? obscure : false,
              decoration: null,
              style: const TextStyle(color: CupertinoColors.white),
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => obscure = !obscure),
              child: Icon(
                obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: CupertinoColors.systemGrey,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0F0F10),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to create a To do list",
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 32),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: const Color(0xFF5E5CE6),
                  
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              _input(
                icon: CupertinoIcons.person,
                placeholder: "Username",
                controller: username,
              ),
              const SizedBox(height: 16),
              _input(
                icon: CupertinoIcons.lock,
                placeholder: "Password",
                controller: password,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF5E5CE6),

                  borderRadius: BorderRadius.circular(14),
                  onPressed: _login,
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    box.clear();
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (_) => const AppRouter()),
                    );
                  },
                  child: const Text(
                    "ERASE DATA",
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
