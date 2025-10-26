import 'package:flutter/material.dart';
 import 'package:flutter_animate/flutter_animate.dart';
 import 'package:flowlink_mobile/ui/app_theme.dart';
 import 'package:font_awesome_flutter/font_awesome_flutter.dart';
 import 'package:flowlink_mobile/ui/onboarding_screen2.dart';
 import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
 import 'package:shared_preferences/shared_preferences.dart';
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(),
      child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: (Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFFAE6), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            )).animate().fadeIn(duration: 500.ms),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!context.mounted) return;
                          final sp = await SharedPreferences.getInstance();
                          await sp.setBool('seen_onboarding_v1', true);
                          Navigator.pushReplacementNamed(context, '/welcome');
                        });
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        final h = c.maxHeight;
                        final s = (w / 375.0).clamp(0.9, 1.15);
                        const m = 20.0;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _NetworkPainter())),
                            Align(
                              alignment: Alignment.center,
                              child: _FloatingBadge(
                                icon: FontAwesomeIcons.appleWhole,
                                bg: const Color(0xFFE8F5E8),
                                fg: AppColors.darkBlue,
                                size: 64 * s,
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: 6, end: -6, duration: 1800.ms, curve: Curves.easeInOut)
                                  .fadeIn(duration: 600.ms),
                            ),
                            Positioned(
                              left: m,
                              bottom: h * 0.18,
                              child: _ScooterBubble(size: 62 * s)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: 4, end: -4, duration: 1500.ms)
                                  .fadeIn(duration: 600.ms, delay: 120.ms),
                            ),
                            Positioned(
                              top: h * 0.12,
                              left: m,
                              child: _FloatingBadge(
                                icon: FontAwesomeIcons.truck,
                                bg: const Color(0xFFE6EEF0),
                                fg: AppColors.greenDark,
                                size: 56 * s,
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: 4, end: -4, duration: 1600.ms)
                                  .fadeIn(duration: 600.ms),
                            ),
                            Positioned(
                              bottom: h * 0.12,
                              right: m,
                              child: _FloatingBadge(
                                icon: FontAwesomeIcons.boxOpen,
                                bg: const Color(0xFFFFF3E0),
                                fg: Colors.black87,
                                size: 52 * s,
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: -5, end: 5, duration: 1700.ms)
                                  .fadeIn(duration: 600.ms, delay: 150.ms),
                            ),
                            Positioned(
                              top: h * 0.22,
                              right: m + w * 0.08,
                              child: _FloatingBadge(
                                icon: FontAwesomeIcons.carrot,
                                bg: const Color(0xFFFFF8E1),
                                fg: Colors.deepOrange,
                                size: 48 * s,
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: 5, end: -5, duration: 1900.ms)
                                  .fadeIn(duration: 600.ms, delay: 300.ms),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Shop Fresh, Everyday!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Order fresh groceries, fruits, and essentials delivered right to your doorstep.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      const _StepDots(activeIndex: 0),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            elevation: 4,
                          ),
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                SlideFadeRoute(page: const OnboardingScreen2(), begin: const Offset(0.12, 0)),
                              );
                            });
                          },
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ScooterBubble extends StatelessWidget {
  final double size;
  const _ScooterBubble({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E0),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(child: FaIcon(FontAwesomeIcons.motorcycle, color: AppColors.greenDark, size: size * 0.46)),
    );
  }
}


class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const _FloatingBadge({required this.icon, required this.bg, required this.fg, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(child: FaIcon(icon, color: fg, size: size * 0.44)),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int activeIndex;
  const _StepDots({required this.activeIndex});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final bool active = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.greenPrimary : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x220F4D42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.65)
      ..cubicTo(size.width * 0.25, size.height * 0.45, size.width * 0.55, size.height * 0.55, size.width * 0.7, size.height * 0.35);
    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.25)
      ..cubicTo(size.width * 0.35, size.height * 0.15, size.width * 0.65, size.height * 0.2, size.width * 0.8, size.height * 0.12);
    final path3 = Path()
      ..moveTo(size.width * 0.25, size.height * 0.8)
      ..cubicTo(size.width * 0.5, size.height * 0.7, size.width * 0.75, size.height * 0.85, size.width * 0.9, size.height * 0.6);
    canvas.drawPath(path1, p);
    canvas.drawPath(path2, p);
    canvas.drawPath(path3, p);
    for (final o in [
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.32, size.height * 0.42),
      Offset(size.width * 0.58, size.height * 0.52),
      Offset(size.width * 0.74, size.height * 0.34),
    ]) {
      canvas.drawCircle(o, 3, Paint()..color = AppColors.darkBlue.withOpacity(0.35));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}