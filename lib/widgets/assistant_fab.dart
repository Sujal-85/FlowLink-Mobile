import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/assistant_notifier.dart';

class AssistantFab extends StatefulWidget {
  const AssistantFab({super.key, required this.onPressed, this.size = 60});

  final VoidCallback onPressed;
  final double size;

  @override
  State<AssistantFab> createState() => _AssistantFabState();
}

class _AssistantFabState extends State<AssistantFab> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _elev;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _elev = Tween<double>(begin: 6.0, end: 10.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return ValueListenableBuilder<int>(
      valueListenable: AssistantNotifier.instance.unread,
      builder: (context, unread, _) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Material(
                color: Colors.transparent,
                elevation: _elev.value,
                shape: const CircleBorder(),
                shadowColor: Colors.black.withOpacity(0.2),
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
