import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient & Subtle Heart Glow
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF0F3),
                  Color(0xFFFFCCD5),
                  Color(0xFFFFB3C1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App Icon / Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'zing',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        TextSpan(
                          text: '.lk',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Simple, genuine dating for Sri Lanka 🇱🇰',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '100% NIC & Selfie Verified Profiles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shadowColor: AppTheme.primary.withOpacity(0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Create Verified Profile'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                    ),
                    child: const Text('Log In with Email'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
