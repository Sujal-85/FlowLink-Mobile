import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/language_intro_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/widgets/success_dialog.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _controllers = List.generate(4, (index) => TextEditingController());
  final _nodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((e) => e.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // If pasted, only take the first character
      _controllers[index].text = value.substring(0, 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }
    if (value.isNotEmpty && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _continue() async {
    if (_code.length == 4) {
      await showSuccessDialog(
        context,
        title: 'You have logged in\nsuccessfully',
        message: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        buttonText: 'Continue',
        onContinue: () {
          pushSlideFade(context, const LanguageIntroScreen());
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit code')),
      );
    }
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
              // Top bar with back
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter OTP',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'We have just sent you 4 digit code via your\nemail ',
                  style: const TextStyle(color: AppColors.textGrey),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) => _OtpBox(
                      controller: _controllers[i],
                      node: _nodes[i],
                      onChanged: (v) => _onChanged(i, v),
                    )),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive code? ", style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Resend Code tapped'))),
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode node;
  final ValueChanged<String> onChanged;
  const _OtpBox({required this.controller, required this.node, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: controller,
        focusNode: node,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
