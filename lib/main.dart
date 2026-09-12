import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stephenscalender2024/accessibility/color_mode_controller.dart';
import 'package:stephenscalender2024/calender/calender_page.dart';
import 'package:stephenscalender2024/firebase_options.dart';
import 'package:stephenscalender2024/homepage/homepage.dart';
import 'package:stephenscalender2024/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EventBundlesProvider()),
        ChangeNotifierProvider(
          create: (context) => ColorModeController()..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorModeController>(
      builder: (context, colorModeController, child) {
        return MaterialApp(
          title: 'Campus Connect',
          debugShowCheckedModeBanner: false,
          theme: AppColorThemes.forMode(colorModeController.mode),
          home: child,
        );
      },
      child: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // PROTOTYPE MODE: login is skipped so this build opens straight into
    // the full app UI for demo/preview purposes. This intentionally
    // bypasses checkAuthenticationStatus() below — restore the
    // FutureBuilder version (see checkAuthenticationStatus) before
    // shipping a real build, since screens that write data (e.g. Add
    // Event) still expect a signed-in Firebase user under the hood.
    return const HomePage();
  }

  Future<bool> checkAuthenticationStatus() async {
    return FirebaseAuth.instance.currentUser != null;
  }
}
