import 'package:flutter/material.dart';
import 'package:flowlink_mobile/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

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
              onPressed: _loading ? null : _change,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _change() async {
    final oldPwd = _old.text.trim();
    final newPwd = _new.text.trim();
    if (newPwd.isEmpty || newPwd != _confirm.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.updatePassword(currentPassword: oldPwd, newPassword: newPwd);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
