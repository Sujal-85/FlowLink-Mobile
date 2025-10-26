import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/notifications_screen.dart';
import 'package:flowlink_mobile/ui/contact_us_screen.dart';
import 'package:flowlink_mobile/ui/faqs_screen.dart';
import 'package:flowlink_mobile/ui/privacy_screen.dart';
import 'package:flowlink_mobile/ui/profile_screen.dart';
import 'package:flowlink_mobile/ui/settings_screen.dart';
import 'package:flowlink_mobile/ui/rate_us_screen.dart';
import 'package:flowlink_mobile/ui/products_list_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Green header
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Daily', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                            Text('Grocery Food', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProductsListScreen(title: 'Search')),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _item(
                          context,
                          icon: Icons.person_outline,
                          label: 'Profile',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.support_agent_outlined,
                          label: 'Contact Us',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactUsScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.help_outline_rounded,
                          label: 'FAQs',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqsScreen())),
                        ),
                        _item(
                          context,
                          icon: Icons.star_rate_outlined,
                          label: 'Rate Us',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RateUsScreen())),
                        ),
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

  Widget _item(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.greenPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
