import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/feedback_repository.dart';

Future<void> showFeedbackDialog(BuildContext context, {required List<String> orderIds}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: 'Feedback',
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, secAnim, child) {
      final scale = Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
      final fade = Tween<double>(begin: 0, end: 1).animate(anim);
      int rating = 0;
      final controller = TextEditingController();
      bool submitting = false;

      return StatefulBuilder(builder: (context, setState) {
        Future<void> submit() async {
          if (rating == 0) return;
          setState(() => submitting = true);
          try {
            await FeedbackRepository.instance.submit(
              orderIds: orderIds,
              rating: rating,
              comment: controller.text,
            );
            if (context.mounted) Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks for your feedback!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
              );
            }
          } finally {
            if (context.mounted) setState(() => submitting = false);
          }
        }

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: Center(
              child: Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.profileGradient,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: const [
                              Icon(Icons.star_rounded, size: 40, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Rate your experience', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                              SizedBox(height: 4),
                              Text('Your feedback helps us improve', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final idx = i + 1;
                            final active = rating >= idx;
                            return IconButton(
                              iconSize: 32,
                              onPressed: () => setState(() => rating = idx),
                              icon: Icon(
                                active ? Icons.star_rounded : Icons.star_border_rounded,
                                color: active ? Colors.amber : Colors.grey.shade400,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: rating > 0 ? 1 : 0.4,
                          duration: const Duration(milliseconds: 150),
                          child: TextField(
                            controller: controller,
                            minLines: 3,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Tell us more (optional)',
                              filled: true,
                            ),
                            enabled: rating > 0 && !submitting,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: submitting ? null : () => Navigator.of(context).pop(),
                                child: const Text('Skip'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: submitting || rating == 0 ? null : submit,
                                child: submitting
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Submit'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      });
    },
  );
}
