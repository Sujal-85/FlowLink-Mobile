import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/language_list_screen.dart';
import 'package:flowlink_mobile/ui/location_intro_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';

class LanguageIntroScreen extends StatefulWidget {
  const LanguageIntroScreen({super.key});

  @override
  State<LanguageIntroScreen> createState() => _LanguageIntroScreenState();
}

class _LanguageIntroScreenState extends State<LanguageIntroScreen> {
  String? _selected;

  void _openList() async {
    final picked = await Navigator.of(context).push<String>(
      SlideFadeRoute(page: LanguageListScreen(selected: _selected)),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  void _continue() {
    pushSlideFade(context, const LocationIntroScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Select your Language',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openList,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected ?? 'Select',
                          style: TextStyle(
                            color: _selected == null ? AppColors.textGrey : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
