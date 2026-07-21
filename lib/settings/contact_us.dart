import 'package:deewan_institute_app/auth/auth_widgets.dart';
import 'package:deewan_institute_app/core/app_bottom_nav.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/app_drawer.dart';
import 'package:deewan_institute_app/core/app_loading.dart';
import 'package:deewan_institute_app/core/app_text_styles.dart';
import 'package:deewan_institute_app/core/app_top_nav.dart';
import 'package:deewan_institute_app/flashcards/review_incorrect_page.dart';
import 'package:deewan_institute_app/settings/policy_widgets.dart';
import 'package:deewan_institute_app/word_search/word_search_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'project@deewandevelopment.com';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  late final _emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? '');
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _encodeQuery(Map<String, String> params) {
    return params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }

  Future<void> _emailUs() async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail, query: _encodeQuery({'subject': 'LinguArabi Support'}));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      _showError('No email app found on this device.');
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendContactMessage');
      await callable.call({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'message': _messageController.text.trim(),
      });
      if (!mounted) return;
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message sent! We'll get back to you soon.", style: TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _showError(e.message ?? 'Could not send your message. Please try again.');
    } catch (_) {
      if (mounted) _showError('Could not send your message. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (i == 1) {
            AppLoading.navigate(context, const WordSearchPage());
            return;
          }
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewIncorrectPage()));
            return;
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTopNav(),
                const SizedBox(height: 24),
                const Text('Contact Us', style: AppTextStyles.headingOne),
                const SizedBox(height: 8),
                const Text(
                  "Questions, feedback, or stuck on something? We'd love to hear from you.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                PolicyCard(
                  children: [
                    const PolicySection(
                      title: 'Email Us Directly',
                      body: 'Prefer your own email app? Reach us any time at:',
                      isLast: true,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _emailUs,
                      child: const Text(
                        _supportEmail,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PolicyCard(
                  children: [
                    const PolicySection(
                      title: 'Send a Message',
                      body: "Fill this out and we'll send it straight to our team.",
                      isLast: true,
                    ),
                    const SizedBox(height: 12),
                    Text('Your Name', style: authLabelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: authFieldDecoration(hint: 'Your name', icon: Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Your Email', style: authLabelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: authFieldDecoration(hint: 'Your email', icon: Icons.mail_outline),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Your Message', style: authLabelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      minLines: 4,
                      maxLines: 8,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: authFieldDecoration(hint: 'How can we help?').copyWith(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a message' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: authPrimaryButtonStyle,
                        onPressed: _isSending ? null : _sendMessage,
                        child: _isSending
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
