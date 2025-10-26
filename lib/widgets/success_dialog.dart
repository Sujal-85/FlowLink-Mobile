import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

Future<void> showSuccessDialog(
  BuildContext context, {
  String title = 'You have logged in\nsuccessfully',
  String message = 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
  String buttonText = 'Continue',
  VoidCallback? onContinue,
}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: 'Success',
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, anim, secAnim, child) {
      final scale = Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
      final fade = Tween<double>(begin: 0, end: 1).animate(anim);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.greenPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onContinue?.call();
                          },
                          child: Text(buttonText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
