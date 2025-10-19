 import 'package:flutter/material.dart';
 import 'dart:math' as math;
 import 'dart:ui' as ui;
 import 'package:flutter_animate/flutter_animate.dart';
 import 'package:flowlink_mobile/ui/app_theme.dart';
 import 'package:font_awesome_flutter/font_awesome_flutter.dart';
 import 'package:flowlink_mobile/ui/onboarding_screen3.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 
class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFFAE6), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                      child: const Text('Skip', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      children: const [
                        SizedBox(height: 8),
                        _DeliveryRoute(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Live tracking on a modern map', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Watch your order move in real time with route, ETA and distance updates.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      const _StepDots(activeIndex: 1),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(shape: const CircleBorder(), elevation: 4),
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 480),
                                  pageBuilder: (_, a, __) => const OnboardingScreen3(),
                                  transitionsBuilder: (_, a, __, child) {
                                    final curved = CurvedAnimation(parent: a, curve: Curves.easeInOutCubic);
                                    final slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved);
                                    final scale = Tween<double>(begin: 0.98, end: 1.0).animate(curved);
                                    return SlideTransition(
                                      position: slide,
                                      child: ScaleTransition(scale: scale, child: child),
                                    );
                                  },
                                ),
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

class _DeliveryRoute extends StatefulWidget {
  const _DeliveryRoute();
  @override
  State<_DeliveryRoute> createState() => _DeliveryRouteState();
}

class _DeliveryRouteState extends State<_DeliveryRoute> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = 280.0;
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: AnimatedBuilder(
          animation: _a,
          builder: (_, __) {
            final bikePos = _pos(w, h, _a.value);
            final bikeAngle = _angle(w, h, _a.value);
            return Stack(children: [
              // Static map-like backdrop
              CustomPaint(size: Size(w, h), painter: const _MapBackdropPainter()),
              // Route (base + animated progress)
              CustomPaint(size: Size(w, h), painter: _RoutePainter(progress: _a.value)),
              // Destination pin at end of the route
              Positioned(
                left: w * 0.88 - 18,
                top: h * 0.28 - 18,
                child: const _PulsingPin(),
              ),
              // Moving courier with subtle glow, following path tangent
              Positioned(
                left: bikePos.dx - 16,
                top: bikePos.dy - 16,
                child: Transform.rotate(
                  angle: bikeAngle,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.greenPrimary.withOpacity(0.35), blurRadius: 18, spreadRadius: 2),
                      ],
                    ),
                    child: const FaIcon(FontAwesomeIcons.motorcycle, color: AppColors.greenDark, size: 28),
                  )
                      .animate(target: 1)
                      .scaleXY(begin: 0.98, end: 1.02, curve: Curves.easeInOut, duration: 900.ms),
                ),
              ),
              // Glass chips for context
              Positioned(
                left: 16,
                top: 14,
                child: const _GlassChip(icon: FontAwesomeIcons.locationArrow, label: 'Pickup'),
              ),
              Positioned(
                right: 16,
                bottom: 14,
                child: const _EtaChip(eta: '12 min', distance: '3.2 km'),
              ),
            ]);
          },
        ),
      );
    });
  }

  // Path helpers for consistent geometry
  Path _routePath(double w, double h) {
    final p0 = Offset(w * 0.08, h * 0.72);
    final p1 = Offset(w * 0.35, h * 0.15);
    final p2 = Offset(w * 0.65, h * 0.85);
    final p3 = Offset(w * 0.88, h * 0.28);
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
  }

  ui.PathMetric _routeMetric(double w, double h) => _routePath(w, h).computeMetrics().first;

  Offset _pos(double w, double h, double t) {
    final metric = _routeMetric(w, h);
    final tangent = metric.getTangentForOffset(metric.length * t);
    return tangent?.position ?? Offset(w * 0.08, h * 0.72);
  }

  double _angle(double w, double h, double t) {
    final metric = _routeMetric(w, h);
    final tangent = metric.getTangentForOffset(metric.length * t);
    if (tangent == null) return 0;
    return math.atan2(tangent.vector.dy, tangent.vector.dx);
  }
}

class _MapBackdropPainter extends CustomPainter {
  const _MapBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    // Soft card background
    final bg = Paint()..color = const Color(0xFFEFF7F0);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)), bg);

    // Faint "streets"
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    Path road1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.30)
      ..cubicTo(size.width * 0.25, size.height * 0.20, size.width * 0.45, size.height * 0.40, size.width * 0.65, size.height * 0.22)
      ..cubicTo(size.width * 0.82, size.height * 0.10, size.width * 0.95, size.height * 0.18, size.width * 0.98, size.height * 0.25);
    Path road2 = Path()
      ..moveTo(size.width * 0.02, size.height * 0.70)
      ..cubicTo(size.width * 0.20, size.height * 0.85, size.width * 0.40, size.height * 0.60, size.width * 0.60, size.height * 0.78)
      ..cubicTo(size.width * 0.80, size.height * 0.92, size.width * 0.96, size.height * 0.88, size.width * 0.98, size.height * 0.80);

    canvas.drawPath(road1, roadPaint);
    canvas.drawPath(road2, roadPaint);

    // Intersections / POIs
    final poi = Paint()..color = const Color(0xFF9EE6B7).withOpacity(0.35);
    for (final o in [
      Offset(size.width * 0.22, size.height * 0.18),
      Offset(size.width * 0.55, size.height * 0.35),
      Offset(size.width * 0.78, size.height * 0.60),
      Offset(size.width * 0.32, size.height * 0.72),
    ]) {
      canvas.drawCircle(o, 6, poi);
    }
  }

  @override
  bool shouldRepaint(covariant _MapBackdropPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final double progress;
  _RoutePainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final p0 = Offset(size.width * 0.08, size.height * 0.72);
    final p1 = Offset(size.width * 0.35, size.height * 0.15);
    final p2 = Offset(size.width * 0.65, size.height * 0.85);
    final p3 = Offset(size.width * 0.88, size.height * 0.28);
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final currentLen = metric.length * progress;
    final progressPath = metric.extractPath(0, currentLen);

    // Base route (subtle)
    final basePaint = Paint()
      ..color = AppColors.greenPrimary.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, basePaint);

    // Glow and main progress
    final glow = Paint()
      ..color = AppColors.greenPrimary.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawPath(progressPath, glow);

    final main = Paint()
      ..color = AppColors.greenPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, main);
  }
  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}

class _PulsingPin extends StatelessWidget {
  const _PulsingPin();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
      child: Center(
        child: const FaIcon(FontAwesomeIcons.locationDot, color: Colors.redAccent, size: 18)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.05, duration: 900.ms)
            .fadeIn(duration: 400.ms)
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 14, color: AppColors.greenDark),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtaChip extends StatelessWidget {
  final String eta;
  final String distance;
  const _EtaChip({required this.eta, required this.distance});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.black87),
              const SizedBox(width: 8),
              Text(eta, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(distance, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}