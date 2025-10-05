import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/assistant_service.dart';
import 'package:flowlink_mobile/services/assistant_notifier.dart';

class AssistantBottomSheet extends StatefulWidget {
  const AssistantBottomSheet({super.key});

  @override
  State<AssistantBottomSheet> createState() => _AssistantBottomSheetState();
}

class _AssistantBottomSheetState extends State<AssistantBottomSheet> {
  final List<AssistantMessage> _messages = [
    const AssistantMessage(role: 'assistant', content: "Hi! I'm your FlowLink assistant. How can I help today?"),
  ];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  final List<String> _quick = const [
    'Track Order',
    'Payment Help',
    'Product Availability',
    'Return Policy',
    'Offers Today',
  ];

  @override
  void initState() {
    super.initState();
    AssistantNotifier.instance.isOpen.value = true;
    AssistantNotifier.instance.resetUnread();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    AssistantNotifier.instance.isOpen.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.4);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: _buildSheet(
        context,
        isDark: isDark,
        bgColor: bgColor,
        borderColor: border,
        bottomInset: bottomInset,
      ),
    );
  }

  Widget _buildSheet(
    BuildContext context, {
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    required double bottomInset,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -6)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark ? Colors.tealAccent.withOpacity(0.2) : Colors.teal.withOpacity(0.15),
                          child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.teal),
                        ),
                        const SizedBox(width: 8),
                        const Text('FlowLink Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_sending && index == _messages.length) {
                          return _typingBubble(isDark: isDark);
                        }
                        final m = _messages[index];
                        final isUser = m.role == 'user';
                        return _bubble(m.content, isUser: isUser, isDark: isDark);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: _quick.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return ActionChip(
                          label: Text(_quick[i]),
                          onPressed: () {
                            _input.text = _quick[i];
                            _send();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _inputBar(isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(String text, {required bool isUser, required bool isDark}) {
    final userColor = const Color(0xFF1E88E5); // blue bubble
    final botColor = isDark ? Colors.grey.shade900.withOpacity(0.7) : Colors.grey.shade100.withOpacity(0.9);

    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = isUser
        ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18))
        : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18));

    return Align(
      alignment: align,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: CircleAvatar(radius: 12, child: Icon(Icons.smart_toy_rounded, size: 14)),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              // Keep bubbles within screen: 80px margin for paddings/avatars
              maxWidth: math.min(MediaQuery.of(context).size.width - 80, 360),
            ),
            decoration: BoxDecoration(
              color: isUser ? userColor : botColor,
              borderRadius: radius,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble({required bool isDark}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900.withOpacity(0.7) : Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(),
            SizedBox(width: 4),
            _Dot(delayMs: 150),
            SizedBox(width: 4),
            _Dot(delayMs: 300),
          ],
        ),
      ),
    );
  }

  Widget _inputBar({required bool isDark}) {
    final fill = Colors.white;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => const SizedBox(height: 150, child: Center(child: Text('Listening… (stub)'))),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(hintText: 'Type a message…', border: InputBorder.none),
                        onTap: _scrollToEnd,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                onPressed: _sending ? null : _send,
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(AssistantMessage(role: 'user', content: text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();

    final reply = await AssistantService.instance.send(_messages);

    if (!mounted) {
      // Sheet closed before reply; mark unread so FAB shows dot.
      AssistantNotifier.instance.markUnread();
      return;
    }

    setState(() {
      _sending = false;
      _messages.add(AssistantMessage(role: 'assistant', content: reply));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _Dot extends StatefulWidget {
  const _Dot({this.delayMs = 0});
  final int delayMs;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _a = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: const CircleAvatar(radius: 4, backgroundColor: Colors.black54),
    );
  }
}
