import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
// Removed legacy colors import

class QuickActionGrid extends StatelessWidget {
  final VoidCallback onPhoneCheck;
  final VoidCallback onBankCheck;
  final VoidCallback onUrlScan;
  final VoidCallback onQrScan;

  const QuickActionGrid({
    super.key,
    required this.onPhoneCheck,
    required this.onBankCheck,
    required this.onUrlScan,
    required this.onQrScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionCard(
              icon: LucideIcons.smartphone,
              label: 'Phone Check',
              onTap: onPhoneCheck,
            ),
            _QuickActionCard(
              icon: LucideIcons.landmark,
              label: 'Account Check',
              onTap: onBankCheck,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionCard(
              icon: LucideIcons.link,
              label: 'URL Scan',
              onTap: onUrlScan,
            ),
            _QuickActionCard(
              icon: LucideIcons.qrCode,
              label: 'QR Scan',
              onTap: onQrScan,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isExpandable;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isExpandable = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 40 - 16) / 2, // 2 items per row
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: DesignTokens.colors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.colors.primary.withOpacity(0.1),
              ),
              child: Icon(icon, color: DesignTokens.colors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.colors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
