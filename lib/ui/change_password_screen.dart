import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _old, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
          const SizedBox(height: 8),
          TextField(controller: _new, obscureText: true, decoration: const InputDecoration(hintText: 'New password')),
          const SizedBox(height: 8),
          TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm new password')),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _change,
              child: const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  void _change() {
    if (_new.text.trim().isEmpty || _new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    Navigator.pop(context);
  }
}
