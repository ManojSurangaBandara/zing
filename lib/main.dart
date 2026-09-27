import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_theme.dart';
import 'services/backend_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/verification_status_screen.dart';
import 'screens/admin/super_admin_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and system UI overlay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize backend (Firebase + Persistent Demo engine)
  final backend = BackendService();
  await backend.initialize();

  runApp(const ZingApp());
}

class ZingApp extends StatelessWidget {
  const ZingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BackendService(),
      builder: (context, _) {
        final backend = BackendService();
        final user = backend.currentUser;

        Widget initialHome;
        if (user == null) {
          initialHome = const WelcomeScreen();
        } else if (user.isSuperAdmin) {
          initialHome = const SuperAdminScreen();
        } else if (user.isApproved) {
          initialHome = const HomeShell();
        } else {
          initialHome = VerificationStatusScreen(user: user);
        }

        return MaterialApp(
          title: 'zing.lk',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: initialHome,
        );
      },
    );
  }
}
