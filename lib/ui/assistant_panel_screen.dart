import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/assistant_service.dart';

class AssistantPanelScreen extends StatefulWidget {
  const AssistantPanelScreen({super.key});

  @override
  State<AssistantPanelScreen> createState() => _AssistantPanelScreenState();
}

class _AssistantPanelScreenState extends State<AssistantPanelScreen> {
  final List<AssistantMessage> _messages = const [
    AssistantMessage(role: 'assistant', content: 'Hi! I\'m your FlowLink assistant. How can I help today?'),
  ].toList();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return _typingBubble();
                  }
                  final m = _messages[index];
                  final isUser = m.role == 'user';
                  return _bubble(m.content, isUser: isUser);
                },
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, {required bool isUser}) {
    final color = isUser ? const Color(0xFFC8F26A) : Colors.white;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
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

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(
                    hintText: 'Ask me anything... ',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              width: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
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
    if (!mounted) return;
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
