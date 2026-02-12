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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
            backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded for modern look
            ),
            elevation: 0, // Flat design
          ),
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
