import 'package:flutter/material.dart';
 import 'package:flutter_animate/flutter_animate.dart';
 import 'package:flowlink_mobile/ui/app_theme.dart';
 import 'package:font_awesome_flutter/font_awesome_flutter.dart';
 import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: buildTheme(),
      child: Scaffold(
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
                    child: Stack(
                      children: [
                        const _PhoneMock()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .moveY(begin: 12, end: 0, duration: 500.ms, curve: Curves.easeOut),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: const FaIcon(FontAwesomeIcons.tags, color: Colors.orange, size: 18)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: 4, end: -4, duration: 1600.ms)
                              .fadeIn(duration: 600.ms),
                        ),
                        Positioned(
                          right: 18,
                          top: 30,
                          child: const FaIcon(FontAwesomeIcons.wallet, color: Color(0xFFFFC107), size: 18)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: -4, end: 4, duration: 1700.ms)
                              .fadeIn(duration: 600.ms, delay: 120.ms),
                        ),
                        Positioned(
                          right: 24,
                          bottom: 6,
                          child: const FaIcon(FontAwesomeIcons.carrot, color: Colors.deepOrange, size: 18)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: 3, end: -3, duration: 1800.ms)
                              .fadeIn(duration: 600.ms, delay: 240.ms),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Smart Shopping Experience', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Discover deals, save your favorites, and enjoy secure payments.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      const _StepDots(activeIndex: 2),
                      SizedBox(
                        width: 180,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!context.mounted) return;
                              final sp = await SharedPreferences.getInstance();
                              await sp.setBool('seen_onboarding_v1', true);
                              Navigator.pushReplacementNamed(context, '/welcome');
                            });
                          },
                          child: const Text('Get Started'),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.04, duration: 1400.ms, curve: Curves.easeInOut),
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

class _PhoneMock extends StatelessWidget {
  const _PhoneMock();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFDFCFB), Color(0xFFF9FFF2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 12, backgroundColor: Color(0xFFE8F5E8)),
                const SizedBox(width: 8),
                const Expanded(child: Text('FlowLink', style: TextStyle(fontWeight: FontWeight.w800))),
                const _DiscountBadge(text: '-25%'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Fresh Apples', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('₹149', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Dairy Milk', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('₹89', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Buy Now'),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.03, duration: 1200.ms, curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final String text;
  const _DiscountBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFFE5B4), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 12)),
    ).animate().fadeIn(duration: 400.ms);
  }
}

enum _SplitType { shopper, retailer }

class _SplitCard extends StatelessWidget {
  final _SplitType type;
  const _SplitCard({required this.type});
  @override
  Widget build(BuildContext context) {
    final isShopper = type == _SplitType.shopper;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isShopper ? [const Color(0xFFE8F5E8), Colors.white] : [const Color(0xFFE6EEF0), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isShopper ? const Color(0xFFC8F26A) : AppColors.darkBlue.withOpacity(0.12),
            child: FaIcon(isShopper ? FontAwesomeIcons.bagShopping : FontAwesomeIcons.chartPie, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isShopper ? 'Shopper' : 'Retailer', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  isShopper ? 'Quick checkout and deals' : 'Insights and fast orders',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms);
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