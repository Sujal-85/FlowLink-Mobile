import 'package:flutter/foundation.dart';

class AssistantNotifier {
  AssistantNotifier._();
  static final AssistantNotifier instance = AssistantNotifier._();

  /// Unread assistant message count to drive FAB red dot.
  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  /// Whether the assistant UI (bottom sheet) is currently open.
  final ValueNotifier<bool> isOpen = ValueNotifier<bool>(false);

  void markUnread([int inc = 1]) {
    if (isOpen.value) return; // don't mark unread while sheet is open
    unread.value = (unread.value + inc).clamp(0, 99);
  }

  void resetUnread() {
    unread.value = 0;
  }
}
