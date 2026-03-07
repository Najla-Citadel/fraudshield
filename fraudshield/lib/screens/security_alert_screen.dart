import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/security_service.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';

class SecurityAlertScreen extends StatelessWidget {
  const SecurityAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldAlert,
                    color: Colors.red,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Security Alert',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your device security integrity has been compromised.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Why am I seeing this?',
                  description:
                      'FraudShield detected that your device is rooted or jailbroken. To protect your financial data and prevent unauthorized access, FraudShield cannot run on modified devices.',
                ),
                const SizedBox(height: 32),
                AppButton(
                  onPressed: () async {
                    final isSecure =
                        await SecurityService.instance.checkSecurity();
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
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // In a real app, you might provide a help link
                  },
                  child: Text(
                    'Learn more about device security',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
