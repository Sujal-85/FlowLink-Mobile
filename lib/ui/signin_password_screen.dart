import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/signup_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:flowlink_mobile/ui/location_intro_screen.dart';

class SignInPasswordScreen extends StatefulWidget {
  final String email;
  const SignInPasswordScreen({super.key, required this.email});

  @override
  State<SignInPasswordScreen> createState() => _SignInPasswordScreenState();
}

class _SignInPasswordScreenState extends State<SignInPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  final bool _loadingGoogle = false;
  final bool _loadingMicrosoft = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  Future<void> _continueWithGoogle() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Sign Up to continue with Google')));
    pushSlideFade(context, const SignupScreen(), begin: const Offset(0.06, 0.0));
  }

  Future<void> _continueWithMicrosoft() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Sign Up to continue with Microsoft')));
    pushSlideFade(context, const SignupScreen(), begin: const Offset(0.06, 0.0));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      pushSlideFade(context, const LocationIntroScreen(), withLoader: true, loadingMessage: 'Signing you in...');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Enter your email address'),
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
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember Me'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Forgot Password tapped'))),
                          style: TextButton.styleFrom(foregroundColor: AppColors.greenPrimary),
                          child: const Text('Forgot Password'),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenPrimary,
                        ),
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Or continue with', style: TextStyle(color: AppColors.textGrey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              _SocialButton(
                icon: FontAwesomeIcons.google,
                label: 'Continue with Google',
                onTap: _loadingGoogle ? null : _continueWithGoogle,
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE4E7EC),
                textColor: Colors.black87,
                iconColor: const Color(0xFF4285F4),
                loading: _loadingGoogle,
              ),
              const SizedBox(height: 12),
              _SocialButton(
                icon: FontAwesomeIcons.microsoft,
                label: 'Continue with Microsoft',
                onTap: _loadingMicrosoft ? null : _continueWithMicrosoft,
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE4E7EC),
                textColor: Colors.black87,
                iconColor: const Color(0xFF00A4EF),
                loading: _loadingMicrosoft,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => pushSlideFade(context, const SignupScreen(), begin: const Offset(0.06, 0.0), withLoader: true, loadingMessage: 'Opening sign up...'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: AppColors.greenPrimary, fontWeight: FontWeight.w600),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final bool loading;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Colors.white;
    final Color fg = textColor ?? Colors.black87;
    final Color bc = borderColor ?? const Color(0xFFE4E7EC);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : FaIcon(icon, color: iconColor ?? fg),
        label: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bc),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: bg,
        ),
      ),
    );
  }
}
