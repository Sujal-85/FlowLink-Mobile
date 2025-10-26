import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/content_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await ContentService.instance.saveContact(
      subject: _subjectCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks! We\'ll get back to you.')));
    Navigator.of(context).pop();
  }

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
                            'Contact us',
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Column(
                              children: const [
                                Text('How can we help you?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                SizedBox(height: 6),
                                Text(
                                  'It looks like you have problems with our product. we are here to help you, so, please get in touch with us.',
                                  style: TextStyle(color: AppColors.textGrey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Subject', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _subjectCtrl,
                                  decoration: const InputDecoration(hintText: "Enter Your problem's subject"),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(hintText: 'Enter Your email'),
                                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _messageCtrl,
                                  minLines: 4,
                                  maxLines: 6,
                                  decoration: const InputDecoration(hintText: 'Enter Your message'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a message' : null,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _sending ? null : _submit,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenPrimary),
                                    child: _sending
                                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Send'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
