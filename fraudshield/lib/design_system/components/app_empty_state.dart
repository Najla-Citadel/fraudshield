import 'package:flutter/material.dart';
import '../tokens/design_tokens.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final double iconSize;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.iconSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    final spacing = DesignTokens.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: colors.textGrey.withOpacity(0.3),
            ),
            SizedBox(height: spacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textGrey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: spacing.xxxl),
              AppButton(
                label: actionLabel!,
                onPressed: onActionPressed,
                variant: AppButtonVariant.secondary,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
