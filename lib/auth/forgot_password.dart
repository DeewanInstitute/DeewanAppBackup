import "dart:async";
import "package:deewan_institute_app/auth/auth_widgets.dart";
import "package:deewan_institute_app/core/app_colors.dart";
import "package:deewan_institute_app/core/app_text_styles.dart";
import "package:deewan_institute_app/core/auth_service.dart";
import "package:deewan_institute_app/core/dashed_border.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "../core/app_navbar.dart";


//There will be 3 stages of forget password
//1 - when the  user recieves it
//2 - when the user send the email
//3 - when the email link expired
enum _Stage { form, sent, expired }

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  static const _linkLifetime = Duration(minutes: 15);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  _Stage _stage = _Stage.form;
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _secondsLeft = _linkLifetime.inSeconds;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  //If the email string is an error, show a snackbar to let the user know
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Timer Format
  String get _formattedCountdown {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Start the countdown as soon as the link is sent to the user
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _linkLifetime.inSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //When the countdown finishes, lead to expired stage.
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _stage = _Stage.expired;
        });
      } else
        //continue with the countdown
        {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendReset() async {
    //If the email is incorrect, return to the page
    if (!_formKey.currentState!.validate()) return;
    //If the emal is correct,
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _stage = _Stage.sent);
      _startCountdown();
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _stage = _Stage.sent);
      _startCountdown();
      _showMessage('Reset link resent.');
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _tryDifferentEmail() {
    _countdownTimer?.cancel();
    setState(() {
      _stage = _Stage.form;
      _emailController.clear();
    });
  }

  Future<void> _openEmailApp() async {
    final uri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      _showError('No email app found on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNavBar(),
              const SizedBox(height: 32),
              switch (_stage) {
                _Stage.form => _buildForm(),
                _Stage.sent => _buildSent(),
                _Stage.expired => _buildExpired(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: _StatusIcon(icon: Icons.lock_outline_rounded, color: AppColors.green, badgeIcon: Icons.question_mark_rounded),
          ),
          const SizedBox(height: 24),
          Text("Forgot Password?", style: AppTextStyles.headingOne, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            "Enter your email and we'll send you a reset link",
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text("Email Address", style: authLabelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: authFieldDecoration(hint: "Enter your email address", icon: Icons.mail_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: authPrimaryButtonStyle,
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
    );
  }

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: _StatusIcon(icon: Icons.mail_outline_rounded, color: AppColors.green, badgeIcon: Icons.check_rounded),
        ),
        const SizedBox(height: 24),
        Text("Check Your Email!", style: AppTextStyles.headingOne.copyWith(color: AppColors.green), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.subheading,
              children: [
                TextSpan(text: "We sent a password reset link to\n"),
                TextSpan(
                  text: _emailController.text,
                  style: const TextStyle(color: AppColors.green, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Link expires in $_formattedCountdown",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: authPrimaryButtonStyle,
            onPressed: _isLoading ? null : _openEmailApp,
            child: const Text("Open Email App"),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _isLoading ? null : _resend,
            child: Text("Resend Link", style: authLinkStyle.copyWith(color: AppColors.muted)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _tryDifferentEmail,
            child: Text("Try a different email", style: authLinkStyle.copyWith(color: AppColors.orange)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: _StatusIcon(icon: Icons.close_rounded, color: AppColors.coral),
        ),
        const SizedBox(height: 24),
        Center(child: Text("Link Expired", style: AppTextStyles.headingOne)),
        const SizedBox(height: 10),
        Text(
          "This reset link has expired or is invalid. Please request a new one.",
          style: AppTextStyles.subheading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _DashedNotice(
          color: AppColors.coral,
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Reset links are valid for 15 minutes only.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.coral),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: authPrimaryButtonStyle,
            onPressed: _isLoading ? null : _resend,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("Request New Link"),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text("Back to Login", style: authLinkStyle.copyWith(color: AppColors.muted)),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final IconData? badgeIcon;
  const _StatusIcon({required this.icon, required this.color, this.badgeIcon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
          ),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
          if (badgeIcon != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Icon(badgeIcon, color: color, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedNotice extends StatelessWidget {
  final Widget child;
  final Color color;
  const _DashedNotice({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      color: color,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
        child: child,
      ),
    );
  }
}
