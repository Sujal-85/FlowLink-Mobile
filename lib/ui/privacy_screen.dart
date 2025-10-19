import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenPrimary, Color(0xFF0F4D42)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: const [
                      BackButton(color: Colors.white),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Privacy',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: const [
                        Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        SizedBox(height: 12),
                        Text(
                          'We value your privacy. This app collects minimal data to enable core features like orders and delivery. Your data is stored securely and never sold to third parties. You can request deletion of your account and data from Settings or by contacting support.',
                          style: TextStyle(color: AppColors.textGrey, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text('Data We Collect', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('- Basic profile info (name, email)\n- Addresses you add for delivery\n- Order history for support and reorders', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
                        SizedBox(height: 16),
                        Text('Your Controls', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('- Edit or delete addresses\n- Sign out anytime\n- Request account deletion via Contact Us', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
