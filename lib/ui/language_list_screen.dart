import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';

class LanguageListScreen extends StatelessWidget {
  final String? selected;
  LanguageListScreen({super.key, this.selected});

  final _languages = const [
    'English (UK)',
    'English',
    'Bahasa Indonesia',
    'Chineses',
    'Croatian',
    'Czech',
    'Danish',
    'Filipino',
    'Finland',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 4),
            const Text('Select a Language', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = lang == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).pop(lang),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE4E7EC), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : const Color(0xFF98A2B3),
                  ),
                  const SizedBox(width: 12),
                  Text(lang, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _languages.length,
      ),
    );
  }
}
