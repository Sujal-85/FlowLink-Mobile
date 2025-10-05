import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class ShareBottomSheet extends StatefulWidget {
  const ShareBottomSheet({super.key, required this.title, required this.link});

  final String title;
  final String link;

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  bool _forSupplier = false; // toggle: false -> Customer, true -> Supplier
  bool _showQr = false;

  String get _message {
    final tag = _forSupplier ? '[Supplier Share]' : '[Customer Share]';
    return '$tag ${widget.title} — ${widget.link}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -6))],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('Share', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Spacer(),
                      _audienceToggle(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _shareTile(icon: Icons.link_rounded, label: 'Copy Link', onTap: _copyLink),
                      _shareTile(icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp', onTap: () => _launch('https://wa.me/?text=${Uri.encodeComponent(_message)}')),
                      _shareTile(icon: Icons.email_outlined, label: 'Email', onTap: () => _launch('mailto:?subject=${Uri.encodeComponent(widget.title)}&body=${Uri.encodeComponent(_message)}')),
                      _shareTile(icon: Icons.send_rounded, label: 'Telegram', onTap: () => _launch('https://t.me/share/url?url=${Uri.encodeComponent(widget.link)}&text=${Uri.encodeComponent(_message)}')),
                      _shareTile(icon: Icons.qr_code_2_rounded, label: _showQr ? 'Hide QR' : 'QR Code', onTap: () => setState(() => _showQr = !_showQr)),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: !_showQr
                      ? const SizedBox(height: 0)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: QrImageView(
                                data: widget.link,
                                version: QrVersions.auto,
                                size: 160,
                                gapless: true,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _audienceToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.grey.shade200,
      ),
      child: Row(
        children: [
          _pill('Customer', !_forSupplier, () => setState(() => _forSupplier = false)),
          _pill('Supplier', _forSupplier, () => setState(() => _forSupplier = true)),
        ],
      ),
    );
  }

  Widget _pill(String text, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? Colors.white : Colors.transparent,
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)] : null,
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: active ? Colors.black87 : Colors.black54)),
      ),
    );
  }

  Widget _shareTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return _AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _launch(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to launch')));
    }
  }
}

class _AnimatedScaleButton extends StatefulWidget {
  const _AnimatedScaleButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _a = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Transform.scale(scale: _a.value, child: child),
        child: widget.child,
      ),
    );
  }
}
