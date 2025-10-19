import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/settings_screen.dart';
import 'package:flowlink_mobile/ui/account_information_screen.dart';
import 'package:flowlink_mobile/ui/payment_methods_screen.dart';
import 'package:flowlink_mobile/ui/address_selection_sheet.dart';
import 'package:flowlink_mobile/ui/assistant_bottom_sheet.dart';
import 'package:flowlink_mobile/ui/security_screen.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/ui/shipping_detail_screen.dart';
import 'package:flowlink_mobile/ui/orders_list_screen.dart';
import 'package:flowlink_mobile/utils/responsive.dart';
import 'package:flowlink_mobile/services/user_service.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:flowlink_mobile/services/user_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flowlink_mobile/widgets/loading_overlay.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                            'Profile',
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: theme.brightness == Brightness.light
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                ValueListenableBuilder<String>(
                                  valueListenable: UserService.instance.photoUrl,
                                  builder: (_, url, __) {
                                    final hasPhoto = url.trim().isNotEmpty;
                                    return CircleAvatar(
                                      radius: 44,
                                      backgroundColor: Colors.white,
                                      backgroundImage: hasPhoto ? NetworkImage(resolveImageUrl(url)) : null,
                                      child: hasPhoto ? null : const Icon(Icons.person, color: Colors.black54),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                ValueListenableBuilder<String>(
                                  valueListenable: UserService.instance.displayName,
                                  builder: (_, name, __) {
                                    final nm = name.trim().isEmpty ? 'Guest' : name.trim();
                                    return Text(nm, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18));
                                  },
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<String>(
                                  valueListenable: UserService.instance.email,
                                  builder: (_, email, __) {
                                    return ValueListenableBuilder<String>(
                                      valueListenable: UserService.instance.phone,
                                      builder: (_, phone, __) {
                                        final info = email.trim().isNotEmpty
                                            ? email.trim()
                                            : (phone.trim().isNotEmpty ? phone.trim() : 'Not signed in');
                                        return Text(info, style: const TextStyle(color: AppColors.textGrey));
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Menu tiles
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountInformationScreen())),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const _ProfileIcon(icon: Icons.person_outline),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Account Information', style: TextStyle(fontWeight: FontWeight.w700))),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const AddressSelectionSheet(),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const _ProfileIcon(icon: Icons.location_on_outlined),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700))),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const _ProfileIcon(icon: Icons.credit_card),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700))),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const _ProfileIcon(icon: Icons.lock_outline),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Password', style: TextStyle(fontWeight: FontWeight.w700))),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: theme.brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Share.share('Check out FlowLink for daily groceries!'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const _ProfileIcon(icon: Icons.group_outlined),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('Reference Friends', style: TextStyle(fontWeight: FontWeight.w700))),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => _confirmLogout(context),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenPrimary),
                              child: const Text('Log Out'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _headerCard(BuildContext context) {
    final r = Responsive.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(r.isSmall ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppColors.profileGradient,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            ValueListenableBuilder<String>(
              valueListenable: UserService.instance.photoUrl,
              builder: (_, url, __) {
                final hasPhoto = url.trim().isNotEmpty;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: r.isSmall ? 26 : 34,
                      backgroundColor: Colors.white,
                      backgroundImage: hasPhoto ? NetworkImage(resolveImageUrl(url)) : null,
                      child: hasPhoto ? null : const Icon(Icons.person, color: Colors.black54),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: () => _changePhoto(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: r.isSmall ? 24 : 28,
                          height: r.isSmall ? 24 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: const Center(child: Icon(Icons.camera_alt, size: 14)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(width: r.scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: UserService.instance.displayName,
                    builder: (_, name, __) {
                      final nm = name.trim().isEmpty ? 'Guest' : name.trim();
                      return Text(
                        nm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: r.sp(r.isSmall ? 16 : 18)),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<String>(
                    valueListenable: UserService.instance.email,
                    builder: (_, email, __) {
                      return ValueListenableBuilder<String>(
                        valueListenable: UserService.instance.phone,
                        builder: (_, phone, __) {
                          final info = email.trim().isNotEmpty
                              ? email.trim()
                              : (phone.trim().isNotEmpty ? phone.trim() : 'Not signed in');
                          return Text(
                            info,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white70, fontSize: r.sp(12)),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<String>(
              valueListenable: UserService.instance.email,
              builder: (_, email, __) {
                return ValueListenableBuilder<String>(
                  valueListenable: UserService.instance.phone,
                  builder: (_, phone, __) {
                    final signedIn = email.trim().isNotEmpty || phone.trim().isNotEmpty;
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: r.scale(36)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: r.scale(14), vertical: r.scale(8)),
                          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(12)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (signedIn) {
                            LoadingOverlay.show(context, message: 'Signing out...');
                            try {
                              await AuthService.instance.signOut();
                            } finally {
                              LoadingOverlay.hide();
                            }
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.pushNamed(context, '/login');
                            }
                          }
                        },
                        child: Text(signedIn ? 'Sign out' : 'Sign in'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = [
      (_Quick(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersListScreen())))),
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
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return _QuickCard(it: it);
        },
      ),
    );
  }

  // Recent Orders compact list
  Widget _recentOrdersSection(BuildContext context) {
    return ValueListenableBuilder<List<OrderItem>>(
      valueListenable: OrdersService.instance.orders,
      builder: (context, orders, _) {
        final list = orders.reversed.take(3).toList();
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Text('No recent orders'),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                _recentOrderTile(context, list[i]),
                if (i != list.length - 1) const SizedBox(height: 10),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _recentOrderTile(BuildContext context, OrderItem o) {
    final expected = '${o.expectedDate.day}/${o.expectedDate.month}';
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingDetailScreen(order: o))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                resolveImageUrl(o.imageUrl.isNotEmpty ? o.imageUrl : 'https://via.placeholder.com/300x300.png?text=Product'),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusBadgeSmall(o.status),
                      const Spacer(),
                      Text('₹${o.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Expected by $expected', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _statusBadgeSmall(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Delivered':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Shipped':
      case 'Out for Delivery':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'Packed':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.black87;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Future<void> _changePhoto(BuildContext context) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 12),
              const Text('Update Profile Photo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Take Photo'), onTap: () => Navigator.pop(ctx, 0)),
              ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from Gallery'), onTap: () => Navigator.pop(ctx, 1)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final source = choice == 0 ? ImageSource.camera : ImageSource.gallery;
    final file = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await file.readAsBytes();
      final url = await UserRepository.instance.uploadProfilePhoto(bytes);
      UserService.instance.setPhotoUrl(url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final r = Responsive.of(context);
    final want = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                child: const Icon(Icons.logout, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              const Text('You will need to sign in again to access your orders and favorites.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.scale(6)),
            ],
          ),
        );
      },
    );
    if (want == true) {
      LoadingOverlay.show(context, message: 'Signing out...');
      try {
        await AuthService.instance.signOut();
      } finally {
        LoadingOverlay.hide();
      }
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: dark ? Colors.white24 : Colors.white, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.greenPrimary),
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
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
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
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.profileGradient),
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
