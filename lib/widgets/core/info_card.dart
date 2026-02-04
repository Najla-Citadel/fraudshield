import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconPath; // Optional asset path
  final IconData? iconData; // Optional icon data
  final VoidCallback onTap;
  final bool isPrimary;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconPath,
    this.iconData,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final textColor = isPrimary ? Colors.white : AppColors.textPrimary;
    final subTextColor = isPrimary ? Colors.white.withOpacity(0.8) : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withOpacity(0.2) : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusS),
              ),
              child: Center(
                child: iconPath != null
                    ? Image.asset(iconPath!, width: 24, height: 24)
                    : Icon(iconData ?? Icons.info, color: isPrimary ? Colors.white : AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodyS.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: subTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
