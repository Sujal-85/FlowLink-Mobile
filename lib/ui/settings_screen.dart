import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowlink_mobile/ui/profile_screen.dart';
import 'package:flowlink_mobile/ui/payment_methods_screen.dart';
import 'package:flowlink_mobile/ui/change_password_screen.dart';
import 'package:flowlink_mobile/ui/forgot_password_screen.dart';
import 'package:flowlink_mobile/ui/security_screen.dart';
import 'package:flowlink_mobile/services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black12,
                child: Icon(Icons.person, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Divya Gokhale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('@DivyaGokhale', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Personal Info
          _sectionTitle('Personal Info'),
          _tile(context, Icons.person_outline, 'Profile', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _tile(context, Icons.account_balance_wallet_outlined, 'Payment Method', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
          }),

          const SizedBox(height: 20),

          // Security
          _sectionTitle('Security'),
          _tile(context, Icons.lock_outline, 'Change Password', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
          }),
          _tile(context, Icons.lock_reset_outlined, 'Forgot Password', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
          }),
          _tile(context, Icons.security_outlined, 'Security', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
          }),

          const SizedBox(height: 20),

          // General
          _sectionTitle('General'),
          _tile(context, Icons.language, 'Language', onTap: () => _showLanguageSheet(context)),
          _tile(context, Icons.delete_outline, 'Clear Cache', trailing: 'App data', onTap: () => _clearCache(context)),

          const SizedBox(height: 20),
          // Appearance / Theme
          _sectionTitle('Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.instance.mode,
            builder: (context, mode, _) {
              String trailing;
              switch (mode) {
                case ThemeMode.light:
                  trailing = 'Light';
                  break;
                case ThemeMode.dark:
                  trailing = 'Dark';
                  break;
                default:
                  trailing = 'System';
              }
              return _tile(context, Icons.brightness_6_outlined, 'Theme', trailing: trailing, onTap: () => _showThemeSheet(context));
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing != null ? Text(trailing, style: const TextStyle(color: Colors.grey)) : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final langs = ['English', 'हिन्दी', 'বাংলা', 'தமிழ்', 'తెలుగు'];
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.language),
            title: Text(langs[i]),
            onTap: () => Navigator.pop(context),
          ),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: langs.length,
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text('This will clear locally stored app data such as cart and addresses.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_entries_v1');
    await prefs.remove('addresses_v1');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
    }
  }

  Future<void> _showThemeSheet(BuildContext context) async {
    final items = <(String, ThemeMode)>[
      ('System', ThemeMode.system),
      ('Light', ThemeMode.light),
      ('Dark', ThemeMode.dark),
    ];
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Choose Theme', style: TextStyle(fontWeight: FontWeight.w800)),
            ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(it.$1),
                  onTap: () {
                    ThemeService.instance.setMode(it.$2);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
