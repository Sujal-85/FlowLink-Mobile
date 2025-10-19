import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/content_service.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  int _openIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenPrimary, Color(0xFF0F4D42)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: const [
                      BackButton(color: Colors.white),
                      Expanded(
                        child: Center(
                          child: Text(
                            'FAQs',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ValueListenableBuilder<List<FaqEntry>>(
                      valueListenable: ContentService.instance.faqs,
                      builder: (_, items, __) {
                        if (items.isEmpty) {
                          return const Center(child: Text('No FAQs yet'));
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final f = items[i];
                            final open = _openIndex == i;
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: open,
                                  maintainState: true,
                                  onExpansionChanged: (v) => setState(() => _openIndex = v ? i : -1),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  title: Text(
                                    f.question,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: AnimatedRotation(
                                    duration: const Duration(milliseconds: 220),
                                    turns: open ? 0.5 : 0.0, // 180° rotation
                                    curve: Curves.easeInOut,
                                    child: const Icon(Icons.expand_more, color: AppColors.greenPrimary),
                                  ),
                                  children: [
                                    Text(
                                      f.answer,
                                      style: const TextStyle(color: AppColors.textGrey, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
