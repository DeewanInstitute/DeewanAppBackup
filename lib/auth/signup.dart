import "package:cloud_firestore/cloud_firestore.dart";
import "package:deewan_institute_app/auth/auth_widgets.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:deewan_institute_app/home/home_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../core/app_navbar.dart";

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  String _dialCode = '+961';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    if (!_agreeToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
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
          'phone': '$_dialCode${_phoneController.text.trim()}',
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
                Text("Create Account", style: AppTextStyles.headingOne),
                const SizedBox(height: 6),
                Text("Join thousands of Arabic learners", style: AppTextStyles.subheading),
                const SizedBox(height: 28),

                Text("Full Name", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: authFieldDecoration(hint: "Enter your full name", icon: Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
                ),
                const SizedBox(height: 18),

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

                Text("Phone Number", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: authFieldDecoration(
                    hint: "Enter your phone number",
                    prefixWidget: PhoneCodePicker(
                      onChanged: (code) => setState(() => _dialCode = code),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 6) ? "Enter a valid phone number" : null,
                ),
                const SizedBox(height: 18),

                Text("Password", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: authFieldDecoration(
                    hint: "Create a password",
                    icon: Icons.lock_outline,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  validator: (v) => (v != null && v.length >= 6) ? null : "Password must be at least 6 characters",
                ),
                PasswordStrengthMeter(password: _passwordController.text),
                const SizedBox(height: 18),

                Text("Confirm Password", style: authLabelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: authFieldDecoration(
                    hint: "Confirm your password",
                    icon: Icons.lock_outline,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  validator: (v) => v == _passwordController.text ? null : "Passwords do not match",
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: AppColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyLight.copyWith(fontSize: 14),
                            children: const [
                              TextSpan(text: "I agree to the "),
                              TextSpan(text: "Terms of Service", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w500)),
                              TextSpan(text: " and "),
                              TextSpan(text: "Privacy Policy", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authPrimaryButtonStyle,
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Create Account"),
                  ),
                ),
                const SizedBox(height: 24),
                const AuthDivider(label: "or sign up with"),
                const SizedBox(height: 20),
                GoogleSignInButton(onTap: () => _showError('Google Sign-In coming soon.')),
                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: AppTextStyles.bodyLight),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text("Sign In", style: authLinkStyle),
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
