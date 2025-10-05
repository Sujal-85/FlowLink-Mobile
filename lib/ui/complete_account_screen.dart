import 'package:flutter/material.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/login_screen.dart';
import 'package:flowlink_mobile/ui/otp_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';

class CompleteAccountScreen extends StatefulWidget {
  final String email;
  const CompleteAccountScreen({super.key, required this.email});

  @override
  State<CompleteAccountScreen> createState() => _CompleteAccountScreenState();
}

class _CompleteAccountScreenState extends State<CompleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      pushSlideFade(context, OTPScreen(email: _emailCtrl.text.trim()));
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
                      decoration: const BoxDecoration(
                        color: AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Complete your account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lorem ipsum dolor sit amet',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('First Name', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(hintText: 'Enter your email address'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your first name' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Last Name', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your last name' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Enter your email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: (v) => (v != _passwordCtrl.text) ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => pushSlideFade(context, const LoginScreen(), begin: const Offset(-0.06, 0.0)),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
