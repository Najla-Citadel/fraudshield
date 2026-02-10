import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isLoading;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final VoidCallback? handledOnPressed = onPressed == null 
      ? null 
      : () {
          HapticFeedback.lightImpact();
          onPressed!();
        };

    if (isIos) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: handledOnPressed,
          disabledColor: CupertinoColors.quaternarySystemFill,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: handledOnPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: isDestructive ? Colors.red : null,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }
}
