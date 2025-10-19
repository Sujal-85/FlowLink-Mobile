 import 'dart:async';
 import 'package:flutter/material.dart';
 import 'package:google_fonts/google_fonts.dart';
 import 'package:flowlink_mobile/services/auth_service.dart';
 import 'package:flowlink_mobile/ui/main_tabs_screen.dart';
 import 'package:flowlink_mobile/ui/welcome_screen.dart';
 import 'package:flowlink_mobile/ui/onboarding_screen.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 import 'package:flowlink_mobile/widgets/slide_fade_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

 @override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
  );
  _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack)),
  );
  _textOpacity = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.95, curve: Curves.easeOut)),
  );
  _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.95, curve: Curves.easeOut)),
  );

  _controller.forward();

  /// 🚀 Wait until the first frame has fully rendered before starting the timer
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;

      final isLoggedIn = AuthService.instance.currentUser != null;
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          SlideFadeRoute(page: const MainTabsScreen(), begin: const Offset(0, 0.04)),
        );
        return;
      }

      final sp = await SharedPreferences.getInstance();
      final seen = sp.getBool('seen_onboarding_v1') ?? false;
      final dest = seen ? const WelcomeScreen() : const OnboardingScreen();
      Navigator.of(context).pushReplacement(
        SlideFadeRoute(page: dest, begin: const Offset(0, 0.04)),
      );
    });
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
             // Centered Logo + tagline
             Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // Animated logo
                   FadeTransition(
                     opacity: _logoOpacity,
                     child: ScaleTransition(
                       scale: _logoScale,
                       child: Image.asset(
                         'assets/images/flowlink-logo-black.png',
                         width: 120,
                         height: 120,
                         fit: BoxFit.contain,
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   // Animated title + tagline
                   FadeTransition(
                     opacity: _textOpacity,
                     child: SlideTransition(
                       position: _textSlide,
                       child: Column(
                         children: [
                           Text(
                             'FlowLink',
                             style: GoogleFonts.mate(
                               fontSize: 32,
                               fontWeight: FontWeight.w700,
                               color: Colors.black,
                             ),
                           ),
                           const SizedBox(height: 8),
                           const Text(
                             'Everyday Needs for You',
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               fontSize: 16,
                               color: Colors.black54,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ),
             // Bottom Version
             Positioned(
               bottom: 20,
               left: 0,
               right: 0,
               child: const Text(
                 'Version 1.0.2',
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.black54,
                 ),
               ),
             ),
           ],
        ),
      ),
    );
  }

   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }
 }