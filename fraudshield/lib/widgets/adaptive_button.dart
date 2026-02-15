import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isLoading;
  final Widget? icon;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
    this.icon,
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

    final textWidget = Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        color: isIos ? Colors.white : colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      ),
    );

    if (isIos) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: handledOnPressed,
          disabledColor: CupertinoColors.quaternarySystemFill,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: icon != null 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  textWidget,
                  const SizedBox(width: 8),
                  icon!,
                ],
              )
            : textWidget,
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: icon != null 
          ? FilledButton.icon(
              onPressed: handledOnPressed,
              icon: icon!,
              label: textWidget,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            )
          : FilledButton(
              onPressed: handledOnPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: textWidget,
            ),
      );
    }
  }
}
