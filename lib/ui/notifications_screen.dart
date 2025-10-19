import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/content_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Green themed header
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
                    children: [
                      _circleIcon(context, Icons.arrow_back_ios_new, onTap: () => Navigator.of(context).pop()),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Notifications',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ValueListenableBuilder<List<NotificationEntry>>(
                      valueListenable: ContentService.instance.notifications,
                      builder: (context, notifications, _) {
                        if (notifications.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.greenPrimary),
                                SizedBox(height: 8),
                                Text('No notifications yet', style: TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(height: 6),
                                Text('We\'ll keep you posted here', style: TextStyle(color: AppColors.textGrey)),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (_, i) {
                            final n = notifications[i];
                            final when = _formatWhen(n.createdAt);
                            return _notificationTile(
                              context,
                              icon: Icons.notifications_active_outlined,
                              iconBg: const Color(0xFFEAF6DB),
                              when: when,
                              title: n.title.isNotEmpty ? n.title : n.body,
                              read: n.read,
                              onTap: () => ContentService.instance.markNotificationRead(n.key, read: true),
                            );
                          },
                        );
                      },
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

Widget _circleIcon(BuildContext context, IconData icon, {VoidCallback? onTap}) {
  return Material(
    color: Colors.white.withOpacity(0.12),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

Widget _notificationTile(
  BuildContext context, {
  required IconData icon,
  required Color iconBg,
  required String when,
  required String title,
  bool read = false,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.greenPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: read
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54)
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatWhen(DateTime dt) {
  // Simple 'MMM d • hh:mm a'
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = months[dt.month - 1];
  final d = dt.day.toString().padLeft(2, '0');
  final hh = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$m $d • $hh:$mm $ampm';
}
