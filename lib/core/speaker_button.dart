import 'package:deewan_institute_app/core/app_colors.dart';
import 'package:deewan_institute_app/core/audio_service.dart';
import 'package:flutter/material.dart';

/// Round speaker button that speaks [text] when tapped. Shows a small spinner
/// while the audio is being fetched, and a snackbar if it can't be played.
class SpeakerButton extends StatefulWidget {
  final String text;
  final AudioDialect dialect;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final double? iconSize;

  const SpeakerButton({
    super.key,
    required this.text,
    this.dialect = AudioDialect.fusha,
    this.size = 40,
    this.backgroundColor = AppColors.orange,
    this.iconColor = Colors.white,
    this.iconSize,
  });

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading || widget.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await AudioService.play(widget.text, dialect: widget.dialect);
    } on AudioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.iconSize ?? widget.size * 0.5;
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.backgroundColor),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: iconSize * 0.9,
                  height: iconSize * 0.9,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.iconColor),
                )
              : Icon(Icons.volume_up_rounded, color: widget.iconColor, size: iconSize),
        ),
      ),
    );
  }
}
