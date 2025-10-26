import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class LoadingOverlay {
  static OverlayEntry? _entry;
  static bool get isShowing => _entry != null;

  static void show(BuildContext context, {String? message, Duration? autoHideAfter}) {
    if (_entry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Dim background and block interactions
          const ModalBarrier(dismissible: false, color: Color(0x22000000)),
          // Slight blur for a polished look
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          // Centered loader card
          Center(
            child: Container
              (
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.greenPrimary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      message ?? 'Loading...'
                    ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);

    if (autoHideAfter != null) {
      Future.delayed(autoHideAfter, hide);
    }
  }

  static void hide() {
    try {
      _entry?.remove();
    } catch (_) {}
    _entry = null;
  }
}
