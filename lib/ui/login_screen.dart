import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/signup_screen.dart';
import 'package:flowlink_mobile/ui/signin_password_screen.dart';
import 'package:flowlink_mobile/widgets/slide_fade_route.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:flowlink_mobile/ui/location_intro_screen.dart';
import 'package:flowlink_mobile/ui/phone_input_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loadingGoogle = false;
  bool _loadingMicrosoft = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    if (!mounted) return;
    setState(() => _loadingGoogle = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      pushSlideFade(context, const LocationIntroScreen(), withLoader: true, loadingMessage: 'Signing you in...');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _continueWithMicrosoft() async {
    if (!mounted) return;
    setState(() => _loadingMicrosoft = true);
    try {
      await AuthService.instance.signInWithMicrosoft();
      if (!mounted) return;
      pushSlideFade(context, const LocationIntroScreen(), withLoader: true, loadingMessage: 'Signing you in...');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingMicrosoft = false);
    }
  }

  void _continueWithEmail() {
    if (_formKey.currentState!.validate()) {
      final email = _emailCtrl.text.trim();
      pushSlideFade(
        context,
        SignInPasswordScreen(email: email),
        withLoader: true,
        loadingMessage: 'Opening sign in...'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: Color(0xFFEAF6DB), shape: BoxShape.circle),
                    child: const Icon(Icons.local_grocery_store_rounded, size: 44, color: Colors.black87),
                  ),
                ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
                const SizedBox(height: 12),
                Center(
                  child: const Text('Welcome to FlowLink', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ).animate().fadeIn(duration: 350.ms, delay: 100.ms).moveY(begin: 8, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 6),
                Center(
                  child: const Text('Fresh groceries delivered fast', style: TextStyle(color: Colors.black54)),
                ).animate().fadeIn(duration: 300.ms, delay: 160.ms),
                const SizedBox(height: 20),
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
                        
                        const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w400),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your email';
                            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _continueWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            child: const Text('Continue with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
                        const SizedBox(height: 24),
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFE4E7EC), thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Or continue with', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE4E7EC), thickness: 1)),
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
                        ).animate().fadeIn(duration: 250.ms, delay: 140.ms),
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
                        ).animate().fadeIn(duration: 250.ms, delay: 180.ms),
                        const SizedBox(height: 12),
                        _SocialButton(
                          icon: FontAwesomeIcons.phone,
                          label: 'Continue with Mobile',
                          onTap: () => pushSlideFade(context, const PhoneInputScreen(), begin: const Offset(0.06, 0.0)),
                          backgroundColor: Colors.white,
                          borderColor: const Color(0xFFE4E7EC),
                          textColor: Colors.black87,
                          iconColor: AppColors.greenPrimary,
                          loading: false,
                        ).animate().fadeIn(duration: 250.ms, delay: 220.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 80.ms).moveY(begin: 8, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                    GestureDetector(
                      onTap: () => pushSlideFade(context, const SignupScreen(), begin: const Offset(0.06, 0.0), withLoader: true),
                      child: Text('Sign Up', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms, delay: 200.ms),
              ],
            ),
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
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FaIcon(icon, color: iconColor ?? fg, size: 20),
        label: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: bc, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}