import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/settings_screen.dart';
import 'package:flowlink_mobile/ui/payment_methods_screen.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
import 'package:flowlink_mobile/ui/security_screen.dart';
import 'package:flowlink_mobile/utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 12),
          _headerCard(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          _quickActions(context),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Preferences section removed: Dark Mode toggle not used
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AssistantBottomSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(r.isSmall ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppColors.primaryGradient,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: r.isSmall ? 26 : 34,
              backgroundColor: Colors.white,
              child: const Icon(Icons.person, color: Colors.black54),
            ),
            SizedBox(width: r.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Divya Gokhale',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: r.sp(r.isSmall ? 16 : 18)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@DivyaGokhale',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: r.sp(12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: r.scale(36)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: r.scale(14), vertical: r.scale(8)),
                  textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = [
      (_Quick(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () => Navigator.pushNamed(context, '/orders'))),
      (_Quick(icon: Icons.credit_card, label: 'Payment', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())))),
      (_Quick(icon: Icons.location_on_outlined, label: 'Addresses', onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddressSelectionSheet(),
        );
      })),
      (_Quick(icon: Icons.security_outlined, label: 'Security', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())))),
      (_Quick(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))),
      (_Quick(icon: Icons.help_outline, label: 'Support', onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AssistantBottomSheet(),
        );
      })),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: () {
            final r = Responsive.of(context);
            return r.isLarge ? 5 : (r.isMedium ? 4 : 3);
          }(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: Responsive.of(context).isSmall ? 1.0 : 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return _QuickCard(it: it);
        },
      ),
    );
  }
}

class _Quick {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.it});
  final _Quick it;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: it.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.scale(44),
              height: r.scale(44),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: Icon(it.icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(it.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(12))),
          ],
        ),
      ),
    );
  }
}
