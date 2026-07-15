import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared white rounded card used by the Privacy Policy and Terms of
/// Service pages to hold their numbered/titled sections.
class PolicyCard extends StatelessWidget {
  final List<Widget> children;
  const PolicyCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final List<String>? bullets;
  final bool italic;
  final bool isLast;
  const PolicySection({
    super.key,
    required this.title,
    required this.body,
    this.bullets,
    this.italic = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.ink,
                height: 1.5,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 8),
            for (final bullet in bullets!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.green, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(bullet, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink, height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Small rounded label used for dates/version badges in page headers.
class PolicyPill extends StatelessWidget {
  final String label;
  final bool outlined;
  const PolicyPill({super.key, required this.label, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : const Color(0xFFEDEAE4),
        borderRadius: BorderRadius.circular(50),
        border: outlined ? Border.all(color: AppColors.green) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: outlined ? AppColors.green : AppColors.muted,
        ),
      ),
    );
  }
}
