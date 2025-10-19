import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/location_intro_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';

class CongratulationsScreen extends StatefulWidget {
  final String? displayName;
  const CongratulationsScreen({super.key, this.displayName});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..addListener(() => setState(() {}))
      ..forward();
    _particles = _blast();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _blast() {
    final rnd = math.Random();
    final particles = <_Particle>[];
    final n = 120;
    for (var i = 0; i < n; i++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final speed = 120 + rnd.nextDouble() * 220; // px/sec
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed - 80; // initial slight upward
      final size = 6 + rnd.nextDouble() * 10;
      final life = 1.6 + rnd.nextDouble() * 0.8; // seconds
      final rot = rnd.nextDouble() * math.pi;
      final rotSpd = (rnd.nextDouble() * 2 - 1) * 6; // rad/sec
      final colorPalette = <Color>[
        const Color(0xFF1DB954), // green
        const Color(0xFFFFC107), // amber
        const Color(0xFFFF6F61), // coral
        const Color(0xFF0F4D42), // dark blue
        const Color(0xFF4DD0E1), // cyan
      ];
      final color = colorPalette[rnd.nextInt(colorPalette.length)];
      final shape = _Shape.values[rnd.nextInt(_Shape.values.length)];
      particles.add(_Particle(
        vx: vx,
        vy: vy,
        size: size,
        color: color,
        life: life,
        rotation: rot,
        rotationSpeed: rotSpd,
        shape: shape,
      ));
    }
    return particles;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Hero check icon
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF6DB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.celebration, size: 56, color: AppColors.greenDark),
                      ),
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
                    const SizedBox(height: 20),
                    Text(
                      'Congratulations',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ).animate().fadeIn(duration: 300.ms, delay: 80.ms).moveY(begin: 6, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      widget.displayName != null && widget.displayName!.trim().isNotEmpty
                          ? '${widget.displayName}, your account has been created successfully.'
                          : 'Your account has been created successfully.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey, height: 1.45),
                    ).animate().fadeIn(duration: 300.ms, delay: 140.ms),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              SlideFadeRoute(page: const LocationIntroScreen(), begin: const Offset(0.06, 0.0)),
                            );
                          });
                        },
                        child: const Text('Continue'),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 180.ms),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Confetti blast overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    t: _controller.value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Shape { rect, circle, triangle }

class _Particle {
  double vx;
  double vy;
  double size;
  final Color color;
  final double life; // seconds
  double rotation;
  final double rotationSpeed; // rad/sec
  final _Shape shape;

  _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1 from animation controller
  _ConfettiPainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Origin around upper center for nicer effect
    final origin = Offset(size.width / 2, size.height * 0.25);
    final gravity = 420.0; // px/sec^2
    final air = 0.18; // air resistance
    final total = 2.6; // controller duration seconds

    for (final p in particles) {
      final time = t * total;
      final alive = time < p.life;
      if (!alive) continue;

      final tt = time;
      final fade = 1 - (tt / p.life).clamp(0.0, 1.0);

      // Position under simple physics
      final dx = p.vx * tt * math.exp(-air * tt);
      final dy = (p.vy * tt + 0.5 * gravity * tt * tt) * math.exp(-air * tt);
      final pos = origin + Offset(dx, dy);

      // Rotation
      final rot = p.rotation + p.rotationSpeed * tt;

      final paint = Paint()
        ..color = p.color.withOpacity(fade)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      switch (p.shape) {
        case _Shape.rect:
          final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size * 1.2, height: p.size * 0.8), const Radius.circular(2));
          canvas.drawRRect(r, paint);
          break;
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case _Shape.triangle:
          final path = Path()
            ..moveTo(0, -p.size * 0.6)
            ..lineTo(p.size * 0.6, p.size * 0.6)
            ..lineTo(-p.size * 0.6, p.size * 0.6)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();

      // trailing sparkle
      if (fade > 0.6) {
        final glow = Paint()
          ..color = p.color.withOpacity((fade - 0.6) * 2 * 0.5)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
        canvas.drawCircle(pos, 2, glow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t || oldDelegate.particles != particles;
}
