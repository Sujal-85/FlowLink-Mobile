import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/login_screen.dart';
import 'package:flowlink_mobile/ui/signup_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top illustration
                AspectRatio(
                  aspectRatio: 375/260,
                  child: Image.asset(
                    'assets/images/image.png',
                    fit: BoxFit.contain,
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 12, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Fast and responsibly\ndelivery by our courier',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey, height: 1.45),
                ).animate().fadeIn(duration: 350.ms, delay: 160.ms),
                const SizedBox(height: 28),
                // Buttons
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => pushSlideFade(context, const SignupScreen(), withLoader: true, loadingMessage: 'Opening sign up...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      elevation: 0,
                      textStyle: const TextStyle(letterSpacing: 0.3, fontWeight: FontWeight.w800),
                    ),
                    child: const Text('CREATE AN ACCOUNT'),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 180.ms),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => pushSlideFade(context, const LoginScreen(), begin: const Offset(0.06, 0.0)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      textStyle: const TextStyle(letterSpacing: 0.2, fontWeight: FontWeight.w800),
                    ),
                    child: const Text('LOGIN'),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 220.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
