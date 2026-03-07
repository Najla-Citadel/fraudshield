import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String message;

  const ErrorState({
    super.key,
    required this.onRetry,
    this.title = 'Connection Failed',
    this.message = 'We couldn\'t fetch the data right now. Please check your connection and try again.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              label: 'Try Again',
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
