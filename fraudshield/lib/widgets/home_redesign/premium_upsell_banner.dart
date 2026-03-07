import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';

class PremiumUpsellBanner extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumUpsellBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radii.md),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        decoration: BoxDecoration(
          color: DesignTokens.colors.premiumYellow,
          borderRadius: BorderRadius.circular(DesignTokens.radii.md),
          boxShadow: DesignTokens.shadows.sm,
        ),
        child: Row(
          children: [
            // Lock Icon Container
            Container(
              padding: EdgeInsets.all(DesignTokens.spacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.lock, color: DesignTokens.colors.premiumYellowText, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock AI Protection',
                    style: TextStyle(
                      color: DesignTokens.colors.premiumYellowText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upgrade to Premium to scan messages, files, APKs & detect scam calls.',
                    style: TextStyle(
                      color: DesignTokens.colors.premiumYellowText.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
