import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import 'package:flutter/cupertino.dart';
import "package:lottie/lottie.dart";

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;
  AnimationController? _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController?.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _submitted = true);
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.arrow_left_circle_fill, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              Text("Forgot Password?", style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text("Enter your email and we'll send you a reset link", style: AppTextStyles.subheading),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Lottie.asset(
                    'assets/animation_lottie/forgotpassword.json',
                    controller: _lottieController,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      _lottieController
                        ?..duration = composition.duration
                        ..repeat();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (!_submitted) ...[
                _card(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email Address", style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: "your@email.com",
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendReset,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Send Reset Link"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                _card(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                      const SizedBox(height: 16),
                      Text("Check Your Email", style: AppTextStyles.heading.copyWith(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text(
                        "We sent a reset link to\n${_emailController.text}",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Back to Login"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    padding: const EdgeInsets.all(24),
    child: child,
  );
}
