import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForce;
  final VoidCallback onUpdate;

  const UpdateDialog({
    super.key,
    required this.isForce,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DesignTokens.colors.backgroundDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DesignTokens.colors.accentGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isForce ? LucideIcons.shieldAlert : LucideIcons.rocket,
                  color: DesignTokens.colors.accentGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isForce ? 'Update Required' : 'New Version Ready',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isForce
                    ? 'A critical update is required to continue using FraudShield safely.'
                    : 'A new version of FraudShield is available with enhanced protection and new features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                onPressed: onUpdate,
                label: 'Update Now',
                variant: AppButtonVariant.primary,
                width: double.infinity,
                size: AppButtonSize.lg,
              ),
              if (!isForce) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
