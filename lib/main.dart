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
    return MaterialApp(
      title: 'zing.lk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastUserKey;

  @override
  void initState() {
    super.initState();
    final user = BackendService().currentUser;
    _lastUserKey = user == null ? 'none' : '${user.id}_${user.status}_${user.role}';
    BackendService().addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    BackendService().removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    final user = BackendService().currentUser;
    final newKey = user == null ? 'none' : '${user.id}_${user.status}_${user.role}';
    if (newKey != _lastUserKey) {
      _lastUserKey = newKey;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();
    final user = backend.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    } else if (user.isSuperAdmin) {
      return const SuperAdminScreen();
    } else if (user.isApproved) {
      return const HomeShell();
    } else {
      return VerificationStatusScreen(user: user);
    }
  }
}
