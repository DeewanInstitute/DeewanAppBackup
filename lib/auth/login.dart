import "package:deewan_institute_app/auth/forgot_password.dart";
import "package:deewan_institute_app/auth/signup.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:deewan_institute_app/home/home_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

import "login_signup.dart";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
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
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginSignup()),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_left_circle_fill,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset(
                      "assets/images/logos/nobgLogo.webp",
                      width: width * 0.60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                    child: Text("Email Address", style: AppTextStyles.labelLarge),
                  ),
                  Center(
                    child: SizedBox(
                      width: width - 55,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                    ),
                  ),
                  // Password
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                    child: Text("Password", style: AppTextStyles.labelLarge),
                  ),
                  Center(
                    child: SizedBox(
                      width: width - 55,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Remember Me + Forgot Password
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        ),
                        Text("Remember me", style: AppTextStyles.bodyLight),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPassword()),
                          ),
                          child: Text("Forgot password?", style: AppTextStyles.link),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login Button
                  Center(
                    child: SizedBox(
                      width: width - 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Login"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Or Continue With", style: AppTextStyles.bodyLight.copyWith(fontSize: 13)),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Google Button
                  Center(
                    child: SizedBox(
                      width: width - 55,
                      child: OutlinedButton(
                        onPressed: () => _showError('Google Sign-In coming soon.'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/images/icons/google.png", height: 22),
                            const SizedBox(width: 10),
                            Text("Google", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Register
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
                          child: Text("Register", style: AppTextStyles.link),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
