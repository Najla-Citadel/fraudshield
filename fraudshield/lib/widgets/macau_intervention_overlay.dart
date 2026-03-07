import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../design_system/tokens/design_tokens.dart';

class MacauInterventionOverlay extends StatelessWidget {
  final Map<String, dynamic> evaluation;

  const MacauInterventionOverlay({
    super.key,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Frosted Glass Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          // 2. Content Container
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
              padding: EdgeInsets.all(DesignTokens.spacing.xxl),
              decoration: BoxDecoration(
                color: DesignTokens.colors.backgroundDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: DesignTokens.shadows.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon & Title
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'CRITICAL WARNING',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Potential Macau Scam Detected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Recommendation text
                  Text(
                    evaluation['recommendation'] ??
                        'STOP! This transaction follows high-risk fraud patterns.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Emergency Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.shield_outlined,
                          label: 'Call NSRC 997',
                          color: Colors.blueAccent,
                          onTap: () => _launchCaller('997'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.phone_in_talk,
                          label: 'Call Police',
                          color: Colors.redAccent,
                          onTap: () => _launchCaller('03-26101559'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Secondary Action
                  TextButton(
                    onPressed: () {
                      NotificationService.instance.dismissIntervention();
                    },
                    child: Text(
                      'I understand. Continue to Details.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchCaller(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
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
          border: Border.all(color: color.withOpacity(0.5)),
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
