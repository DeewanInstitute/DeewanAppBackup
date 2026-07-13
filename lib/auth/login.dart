import "package:deewan_institute_app/auth/auth_widgets.dart";
import "package:deewan_institute_app/auth/forgot_password.dart";
import "package:deewan_institute_app/auth/signup.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:deewan_institute_app/home/home_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../core/app_navbar.dart";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNavBar(),
                const SizedBox(height: 24),
                Text("Welcome Back!", style: AppTextStyles.headingOne),
                const SizedBox(height: 6),
                Text("Continue your Arabic journey", style: AppTextStyles.subheading),
                const SizedBox(height: 32),

                Text("Email Address", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: authFieldDecoration(hint: "Enter your email", icon: Icons.mail_outline),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                Text("Password", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: authFieldDecoration(
                    hint: "Enter your password",
                    icon: Icons.lock_outline,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPassword()),
                    ),
                    child: const Text("Forgot Password?", style: authLinkStyle),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authPrimaryButtonStyle,
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Log In"),
                  ),
                ),
                const SizedBox(height: 28),
                const AuthDivider(label: "or continue with"),
                const SizedBox(height: 20),
                GoogleSignInButton(onTap: () => _showError('Google Sign-In coming soon.')),
                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: AppTextStyles.bodyLight),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUp()),
                        ),
                        child: const Text("Sign Up", style: authLinkStyle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
