import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_controller.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Branding
              Text(
                "ተፍ ተፍ",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Dark branding
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your Premium Marketplace",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Sign-in buttons
              _buildSignInButton(
                iconPath: 'assets/google_icon_white.png',
                label: "Continue with Google",
                color: Colors.white,
                onPressed: () async {
                  await authController.signInWithGoogle();
                  if (authController.state.user != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                isOutlined: true, // Outlined for white-on-white visibility
                textColor: Colors.black87,
                isGoogle: true,
              ),
              const SizedBox(height: 16),
              /*
              _buildSignInButton(
                iconPath: 'assets/facebook_icon_blue.png',
                label: "Continue with Facebook",
                color: const Color(0xFF1877F2),
                onPressed: () async {
                  await authController.signInWithFacebook();
                  if (authController.state.user != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                isOutlined: false,
                textColor: Colors.white,
                isGoogle: false,
              ),
              */
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text(
                  "Skip for now",
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required String iconPath,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isOutlined,
    required Color textColor,
    required bool isGoogle,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined ? BorderSide(color: Colors.black12, width: 1) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  isGoogle ? Icons.g_mobiledata : Icons.facebook,
                  size: 28,
                  color: isGoogle ? Colors.red : const Color(0xFF1877F2),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
