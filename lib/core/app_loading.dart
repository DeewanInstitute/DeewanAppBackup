import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoading {
  static Future<void> navigate(
    BuildContext context,
    Widget page, {
    bool clearStack = false,
  }) async {
    final navigator = Navigator.of(context);

    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      barrierColor: Colors.white.withValues(alpha: 0.90),
      builder: (_) => const _LoadingDialog(),
    );

    await Future.delayed(const Duration(milliseconds: 1900));

    if (!navigator.mounted) return;
    navigator.pop();

    if (!navigator.mounted) return;
    if (clearStack) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (_) => false,
      );
    } else {
      navigator.push(MaterialPageRoute(builder: (_) => page));
    }
  }
}

class _LoadingDialog extends StatefulWidget {
  const _LoadingDialog();

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animation_lottie/loading.json',
        width: 300,
        height: 300,
        controller: _controller,
        onLoaded: (composition) {
          if (!mounted) return;
          setState(() {
            _controller = AnimationController(vsync: this, duration: composition.duration)
              ..repeat();
          });
        },
      ),
    );
  }
}
