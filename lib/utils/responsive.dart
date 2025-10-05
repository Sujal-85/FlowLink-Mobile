import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight responsive helpers for consistent sizing across devices.
///
/// Usage:
///   final r = Responsive.of(context);
///   final spacing = r.scale(16);
///   final title = r.sp(20);
///   final boxW = r.wp(50); // 50% of screen width
class Responsive {
  Responsive._(this._mq)
      : width = _mq.size.width,
        height = _mq.size.height,
        _baseScale = (_mq.size.width / 375.0).clamp(0.85, 1.25).toDouble();

  final MediaQueryData _mq;
  final double width;
  final double height;
  final double _baseScale;

  static Responsive of(BuildContext context) => Responsive._(MediaQuery.of(context));

  // Width percentage
  double wp(double percent) => width * percent / 100;

  // Height percentage
  double hp(double percent) => height * percent / 100;

  // Scaled font size with gentle clamp for readability
  double sp(double fontSize) => fontSize * textScale;

  // Scaled size for paddings, radii, etc.
  double scale(double size) => size * _baseScale;

  // Derived text scale factor
  double get textScale => _clamp(_baseScale, 0.9, 1.2);

  // Breakpoints
  bool get isSmall => width < 360;
  bool get isMedium => width >= 360 && width < 480;
  bool get isLarge => width >= 480;

  double _clamp(double v, double min, double max) => math.min(max, math.max(min, v));
}
