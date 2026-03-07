import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/security_service.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/glass_surface.dart';

class SecurityAlertScreen extends StatelessWidget {
  const SecurityAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Security Alert',
      showBackButton: false, // Critical alert screen, usually shouldn't just go back
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacing.xxl),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.shieldAlert,
                  color: DesignTokens.colors.error,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Security Compromised',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your device security integrity has been compromised.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const GlassSurface(
                padding: EdgeInsets.all(20),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why am I seeing this?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'FraudShield detected that your device is rooted or jailbroken. To protect your financial data and prevent unauthorized access, FraudShield cannot run on modified devices.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              AppButton(
                onPressed: () async {
                  final isSecure = await SecurityService.instance.checkSecurity();
                  if (isSecure) {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  } else {
                    if (context.mounted) {
                      AppSnackBar.showError(context, 'Security threat still detected.');
                    }
                  }
                },
                label: 'Re-verify Security',
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Learn more about device security',
                  style: TextStyle(
                    color: DesignTokens.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
