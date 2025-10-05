import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Enter your registered email to receive reset instructions.'),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _send,
              child: const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link sent (stub)')));
    Navigator.pop(context);
  }
}
