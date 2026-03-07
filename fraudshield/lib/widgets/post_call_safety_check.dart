import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/notification_service.dart';
import '../app_router.dart';
import '../design_system/tokens/design_tokens.dart';

class PostCallSafetyCheck extends StatelessWidget {
  final Map<String, dynamic> data;

  const PostCallSafetyCheck({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Frosted Glass Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          // Content Container
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
              padding: EdgeInsets.all(DesignTokens.spacing.xxl),
              decoration: BoxDecoration(
                color: DesignTokens.colors.backgroundDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: DesignTokens.shadows.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.shieldAlert,
                      color: Colors.orangeAccent,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Safety Check',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Did the previous caller ask you to transfer money or provide your OTP/password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: LucideIcons.check,
                          label: 'No, I\'m Safe',
                          color: Colors.greenAccent,
                          onTap: () {
                            NotificationService.instance.dismissPostCallCheck();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: LucideIcons.flag,
                          label: 'Yes, Report',
                          color: Colors.redAccent,
                          onTap: () {
                            NotificationService.instance.dismissPostCallCheck();
                            AppRouter.navigatorKey.currentState
                                ?.pushNamed('/report');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radii.md),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(DesignTokens.radii.md),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
