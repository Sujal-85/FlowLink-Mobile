import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                            'Terms of Service',
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
                        Text('Welcome to FlowLink', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        SizedBox(height: 12),
                        Text(
                          'By using FlowLink, you agree to these terms. Please read them carefully. These terms outline your rights and responsibilities, including acceptable use, orders and payments, returns, and limitations of liability.',
                          style: TextStyle(color: AppColors.textGrey, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text('Use of Service', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('- Provide accurate information when creating an account.\n- Do not misuse the app (e.g., fraud, abuse, malicious behavior).', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
                        SizedBox(height: 16),
                        Text('Orders & Payments', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('- Prices and availability may change.\n- Refunds/returns are subject to policy displayed at checkout.', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
                        SizedBox(height: 16),
                        Text('Contact', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('For questions, contact support from the app.', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
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
