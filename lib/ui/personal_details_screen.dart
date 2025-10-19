import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/user_repository.dart';
import 'package:flowlink_mobile/services/user_service.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/ui/congratulations_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final name = UserService.instance.displayName.value.trim();
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      _firstCtrl.text = parts.isNotEmpty ? parts.first : '';
      _lastCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    _emailCtrl.text = UserService.instance.email.value.trim();
    // Prefill from backend if present
    Future.microtask(() async {
      try {
        final data = await UserRepository.instance.getProfile();
        if (!mounted || data == null) return;
        setState(() {
          _firstCtrl.text = (data['firstName'] ?? _firstCtrl.text).toString();
          _lastCtrl.text = (data['lastName'] ?? _lastCtrl.text).toString();
          final em = (data['email'] ?? _emailCtrl.text).toString();
          if (em.isNotEmpty) _emailCtrl.text = em;
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final first = _firstCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final display = [first, last].where((s) => s.isNotEmpty).join(' ');
      await UserRepository.instance.updateProfile(
        firstName: first,
        lastName: last,
        email: email.isEmpty ? null : email,
        displayName: display.isEmpty ? null : display,
      );
      UserService.instance.setUser(name: display, emailAddress: email.isNotEmpty ? email : null);
      if (!mounted) return;
      pushSlideFade(
        context,
        CongratulationsScreen(displayName: display),
        withLoader: true,
        loadingMessage: 'Saving details...'
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Personal details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Tell us a bit about you to personalize your experience', style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First Name', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _firstCtrl,
                        decoration: const InputDecoration(hintText: 'Enter your first name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your first name' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('Last Name', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lastCtrl,
                        decoration: const InputDecoration(hintText: 'Enter your last name'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Email (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Enter your email'),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return null;
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save & Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
