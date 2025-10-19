import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowlink_mobile/ui/profile_screen.dart';
import 'package:flowlink_mobile/ui/payment_methods_screen.dart';
import 'package:flowlink_mobile/ui/change_password_screen.dart';
import 'package:flowlink_mobile/ui/forgot_password_screen.dart';
import 'package:flowlink_mobile/ui/security_screen.dart';
import 'package:flowlink_mobile/services/theme_service.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flowlink_mobile/services/user_service.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/widgets/loading_overlay.dart';

// Brand palette
const kBrandGreen = Color(0xFF27AE60);  // Fresh Green
const kCtaOrange = Color(0xFFF39C12);   // Energetic Orange
const kBgOffWhite = Color(0xFFF8F9FA);  // Clean Off-White
const kTextCharcoal = Color(0xFF34495E); // Charcoal Gray

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _email = true;
  bool _sms = false;
  bool _analytics = true;
  bool _ads = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _push = p.getBool('notif_push') ?? true;
      _email = p.getBool('notif_email') ?? true;
      _sms = p.getBool('notif_sms') ?? false;
      _analytics = p.getBool('privacy_analytics') ?? true;
      _ads = p.getBool('privacy_personalized_ads') ?? false;
    });
  }

  Future<void> _savePref(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: on),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold).copyWith(color: on),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Row(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: UserService.instance.photoUrl,
                builder: (_, url, __) {
                  final hasPhoto = url.trim().isNotEmpty;
                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: kBrandGreen,
                    backgroundImage: hasPhoto ? NetworkImage(resolveImageUrl(url)) : null,
                    child: hasPhoto ? null : const Icon(Icons.person, color: Colors.white),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: UserService.instance.displayName,
                    builder: (_, name, __) => Text(
                      name.trim().isEmpty ? 'Guest' : name.trim(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(color: on),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<String>(
                    valueListenable: UserService.instance.email,
                    builder: (_, email, __) => Text(
                      email.trim().isEmpty ? 'Not signed in' : email.trim(),
                      style: TextStyle(color: on.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: UserService.instance.phone,
                    builder: (_, phone, __) => Text(
                      phone.trim(),
                      style: TextStyle(color: on.withOpacity(0.6)),
                    ),
                  ),
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
          _tile(context, Icons.location_on_outlined, 'Addresses', onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddressSelectionSheet(),
            );
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

          // Notifications
          _sectionTitle('Notifications'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Push Notifications', style: TextStyle(color: on)),
            value: _push,
            onChanged: (v) {
              setState(() => _push = v);
              _savePref('notif_push', v);
            },
            activeThumbColor: kBrandGreen,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Email Updates', style: TextStyle(color: on)),
            value: _email,
            onChanged: (v) {
              setState(() => _email = v);
              _savePref('notif_email', v);
            },
            activeThumbColor: kBrandGreen,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('SMS Alerts', style: TextStyle(color: on)),
            value: _sms,
            onChanged: (v) {
              setState(() => _sms = v);
              _savePref('notif_sms', v);
            },
            activeThumbColor: kBrandGreen,
          ),

          const SizedBox(height: 20),

          // Privacy
          _sectionTitle('Privacy'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Share Analytics', style: TextStyle(color: on)),
            value: _analytics,
            onChanged: (v) {
              setState(() => _analytics = v);
              _savePref('privacy_analytics', v);
            },
            activeThumbColor: kBrandGreen,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Personalized Offers', style: TextStyle(color: on)),
            value: _ads,
            onChanged: (v) {
              setState(() => _ads = v);
              _savePref('privacy_personalized_ads', v);
            },
            activeThumbColor: kBrandGreen,
          ),

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

          const SizedBox(height: 20),
          _sectionTitle('About'),
          _tile(context, Icons.info_outline, 'Version', trailing: 'v1.0.0'),
          _tile(context, Icons.description_outlined, 'Terms of Service', onTap: () => launchUrlString('https://www.example.com/terms')),
          _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => launchUrlString('https://www.example.com/privacy')),

          const SizedBox(height: 20),
          _sectionTitle('Account'),
          _tile(context, Icons.logout, 'Sign out', onTap: () async {
            LoadingOverlay.show(context, message: 'Signing out...');
            try {
              await AuthService.instance.signOut();
            } finally {
              LoadingOverlay.hide();
            }
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }),
          _tile(context, Icons.delete_forever_outlined, 'Delete Account', onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Delete account?', style: TextStyle(color: on, fontWeight: FontWeight.w700)),
                content: Text('This is a demo action and will only clear local data.', style: TextStyle(color: on.withOpacity(0.8))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: on))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (ok == true) {
              final p = await SharedPreferences.getInstance();
              await p.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted (local data cleared)')));
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            }
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kBrandGreen),
      title: Text(title, style: const TextStyle(fontSize: 16).copyWith(color: Theme.of(context).colorScheme.onSurface)),
      trailing: trailing != null
          ? Text(trailing, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
          : Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
            leading: Icon(Icons.language, color: kBrandGreen),
            title: Text(langs[i], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
        title: Text('Clear cache?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        content: Text('This will clear locally stored app data such as cart and addresses.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: kCtaOrange, fontWeight: FontWeight.w600)),
          ),
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
            Text('Choose Theme', style: const TextStyle(fontWeight: FontWeight.w800).copyWith(color: Theme.of(context).colorScheme.onSurface)),
            ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  leading: Icon(Icons.brightness_6_outlined, color: kBrandGreen),
                  title: Text(it.$1, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
