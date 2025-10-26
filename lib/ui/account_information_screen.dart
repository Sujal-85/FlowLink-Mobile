import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/services/user_repository.dart';
import 'package:flowlink_mobile/services/user_service.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() => _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    _name.text = UserService.instance.displayName.value.trim();
    _email.text = UserService.instance.email.value.trim();
    _phone.text = UserService.instance.phone.value.trim();
    try {
      final data = await UserRepository.instance.getProfile();
      if (!mounted || data == null) return;
      setState(() {
        final dn = (data['displayName'] ?? '').toString().trim();
        if (dn.isNotEmpty) _name.text = dn;
        _username.text = (data['username'] ?? '').toString();
        final ph = (data['phone'] ?? '').toString().trim();
        if (ph.isNotEmpty) _phone.text = ph;
        final em = (data['email'] ?? '').toString().trim();
        if (em.isNotEmpty) _email.text = em;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final display = _name.text.trim();
      final username = _username.text.trim();
      final email = _email.text.trim();
      final phone = _phone.text.trim();
      await UserRepository.instance.updateProfile(
        displayName: display.isEmpty ? null : display,
        email: email.isEmpty ? null : email,
        username: username.isEmpty ? null : username,
        phone: phone.isEmpty ? null : phone,
      );
      UserService.instance.setUser(
        name: display,
        emailAddress: email.isNotEmpty ? email : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account info saved')));
      Navigator.maybePop(context);
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
                            'Account Information',
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: theme.brightness == Brightness.light
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(hintText: 'Enter Your Full Name', prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                              ),
                              const SizedBox(height: 14),
                              const Text('Username', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _username,
                                decoration: const InputDecoration(hintText: 'Enter Your Username', prefixIcon: Icon(Icons.alternate_email)),
                              ),
                              const SizedBox(height: 14),
                              const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(hintText: 'Enter Your Email Address', prefixIcon: Icon(Icons.mail_outline)),
                                validator: (v) {
                                  final val = v?.trim() ?? '';
                                  if (val.isEmpty) return null;
                                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              const Text('Phone number', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: 'Enter Your Phone Number', prefixIcon: Icon(Icons.call_outlined)),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenPrimary),
                                  child: _saving
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
