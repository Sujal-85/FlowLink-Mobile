import 'package:flutter/material.dart';

class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset begin;
  final Duration duration;
  final Curve curve;

  SlideFadeRoute({
    required this.page,
    this.begin = const Offset(0.0, 0.06),
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(begin: begin, end: Offset.zero)
                .chain(CurveTween(curve: curve));
            final fadeTween = Tween<double>(begin: 0, end: 1)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

Future<T?> pushSlideFade<T>(BuildContext context, Widget page,
    {Offset begin = const Offset(0.0, 0.06)}) {
  return Navigator.of(context).push<T>(
    SlideFadeRoute<T>(page: page, begin: begin),
  );
}
