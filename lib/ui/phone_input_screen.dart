import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/ui/otp_screen.dart';

class InfiniteProductsStrip extends StatefulWidget {
  final List<String> images;
  final bool reverse;
  final double itemSize;
  final double gap;
  final Duration duration;

  const InfiniteProductsStrip({
    super.key,
    required this.images,
    this.reverse = false,
    this.itemSize = 72,
    this.gap = 12,
    this.duration = const Duration(seconds: 18),
  });

  @override
  State<InfiniteProductsStrip> createState() => _InfiniteProductsStripState();
}

class _InfiniteProductsStripState extends State<InfiniteProductsStrip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRow(List<String> items) {
    final rowWidth = items.length * (widget.itemSize + widget.gap);
    return OverflowBox(
      minWidth: 0,
      maxWidth: double.infinity,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: rowWidth,
        child: Row(
          children: [
            for (final a in items)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
                child: Container(
                  width: widget.itemSize,
                  height: widget.itemSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAE6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(a, fit: BoxFit.contain),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemSize + 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final base = widget.images;
          final List<String> imgs = [];
          final tileW = widget.itemSize + widget.gap;
          final targetWidth = constraints.maxWidth * 1.4;
          while ((imgs.length * tileW) < targetWidth) {
            imgs.addAll(base);
            if (imgs.length > 50) break; // safety
          }
          if (imgs.isEmpty) imgs.addAll(base);
          final travel = imgs.length * tileW;

          return ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value; // 0..1
                final double x = widget.reverse ? (t * travel) : (-t * travel);
                final firstX = x;
                final secondX = widget.reverse ? x - travel : x + travel;
                return Stack(
                  children: [
                    Transform.translate(offset: Offset(firstX, 0), child: _buildRow(imgs)),
                    Transform.translate(offset: Offset(secondX, 0), child: _buildRow(imgs)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AnimatedProductRows extends StatelessWidget {
  final List<String> images;
  const AnimatedProductRows({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    double base = (w / 375.0) * 68.0;
    final double tile = base < 56.0
        ? 56.0
        : (base > 80.0
            ? 80.0
            : base);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InfiniteProductsStrip(images: images, reverse: false, itemSize: tile, duration: const Duration(seconds: 16)),
                    const SizedBox(height: 8),
                    InfiniteProductsStrip(images: images.reversed.toList(), reverse: true, itemSize: tile, duration: const Duration(seconds: 18)),
                    const SizedBox(height: 8),
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                      child: InfiniteProductsStrip(images: images, reverse: false, itemSize: tile, duration: const Duration(seconds: 20)),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00FFFFFF), Colors.white],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});
  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCtrl = TextEditingController(text: '+91');
  final _phoneCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _buildE164(String country, String number) {
    final c = country.trim();
    final n = number.replaceAll(RegExp(r'[^0-9]'), '');
    final cc = c.startsWith('+') ? c : '+$c';
    return '$cc$n';
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final e164 = _buildE164(_countryCtrl.text, _phoneCtrl.text);
    setState(() => _sending = true);
    try {
      await AuthService.instance.startPhoneVerification(
        phoneNumber: e164,
        onCodeSent: (id, token) {
          if (!mounted) return;
          Navigator.of(context).push(
            SlideFadeRoute(
              page: OTPScreen(
                verificationId: id,
                phoneNumber: e164,
                resendToken: token,
              ),
              begin: const Offset(0.06, 0),
            ),
          );
        },
        onError: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Failed to send OTP')),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedProductRows(
                images: const [
                  'assets/products/amul-milk.jpeg',
                  'assets/products/basmati-rice.jpeg',
                  'assets/products/fortune-oil.jpeg',
                  'assets/products/fresheggs.jpeg',
                  'assets/products/gokul-besan.jpeg',
                  'assets/products/madhur-sugar.jpeg',
                  'assets/products/maggi-12.jpeg',
                  'assets/products/maggi-noddles.jpeg',
                  'assets/products/tata-salt.jpeg',
                  'assets/products/teatime-bakes.jpeg',
                  'assets/products/toor-dal.jpeg',
                ],
              ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/images/FlowLink-logo-text.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "India's last minute app",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 16),
                    children: [
                      TextSpan(
                        text: 'Log In',
                        style: const TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).pushNamed('/login'),
                      ),
                      const TextSpan(text: '  or  '),
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).pushNamed('/signup'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _countryCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: '+91'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Code' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: 'Enter Phone number'),
                          validator: (v) {
                            final n = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                            if (n.length < 7) return 'Enter valid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms).moveY(begin: 8, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendCode,
                  child: _sending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send OTP'),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: 120.ms),
            ],
          ),
        ),
      ),
    );
  }
}
