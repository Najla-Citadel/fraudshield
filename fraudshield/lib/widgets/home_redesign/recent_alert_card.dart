import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

enum AlertSeverity { high, warning, info }

class RecentAlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final AlertSeverity severity;
  final VoidCallback onReview;

  const RecentAlertCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.severity = AlertSeverity.high,
    required this.onReview,
  });

  Color get _backgroundColor {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFFFF5F5); // Light red
      case AlertSeverity.warning:
        return const Color(0xFFFFFBEB); // Light yellow/orange
      case AlertSeverity.info:
        return const Color(0xFFEFF6FF); // Light blue
    }
  }

  Color get _borderColor {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFFFE0E0);
      case AlertSeverity.warning:
        return const Color(0xFFFEF08A);
      case AlertSeverity.info:
        return const Color(0xFFBFDBFE);
    }
  }

  Color get _iconBackgroundColor {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFEF4444); // Red
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B); // Amber/Orange
      case AlertSeverity.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData get _iconData {
    switch (severity) {
      case AlertSeverity.high:
        return LucideIcons.alertCircle;
      case AlertSeverity.warning:
        return LucideIcons.alertTriangle;
      case AlertSeverity.info:
        return LucideIcons.info;
    }
  }

  Color get _titleColor {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFF991B1B);
      case AlertSeverity.warning:
        return const Color(0xFF92400E); // Dark amber
      case AlertSeverity.info:
        return const Color(0xFF1E3A8A); // Dark blue
    }
  }

  Color get _subtitleColor {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFB91C1C);
      case AlertSeverity.warning:
        return const Color(0xFFB45309);
      case AlertSeverity.info:
        return const Color(0xFF2563EB); // Medium blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReview,
      borderRadius: BorderRadius.circular(DesignTokens.radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: _backgroundColor, 
          borderRadius: BorderRadius.circular(DesignTokens.radii.md),
          border: Border.all(color: _borderColor, width: 1), 
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconBackgroundColor, 
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _titleColor, 
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _subtitleColor, 
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
