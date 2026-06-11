import "package:cloud_firestore/cloud_firestore.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:deewan_institute_app/home/home_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/cupertino.dart";

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService.signUpWithEmail(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Non-critical: user is already created in Firebase Auth
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
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
                child: const Icon(
                  CupertinoIcons.arrow_left_circle_fill,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text("Create Account", style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text("Fill in your details to get started", style: AppTextStyles.subheading),
              const SizedBox(height: 32),
              _card(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Full Name", style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: "e.g. Ahmad Al-Hassan"),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
                      ),
                      const SizedBox(height: 20),
                      Text("Email Address", style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: "your@email.com"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text("Password", style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "At least 6 characters",
                          suffixIcon: _toggleIcon(_obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                        ),
                        validator: (v) => (v != null && v.length >= 6) ? null : "Password must be at least 6 characters",
                      ),
                      const SizedBox(height: 20),
                      Text("Confirm Password", style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: "Re-enter password",
                          suffixIcon: _toggleIcon(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                        ),
                        validator: (v) => v == _passwordController.text ? null : "Passwords do not match",
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Sign Up"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?", style: AppTextStyles.bodyLight),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text("Login", style: AppTextStyles.link),
                  ),
                ],
              ),
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

  Widget _toggleIcon(bool obscure, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38),
  );
}
