import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/security_score_gauge.dart';

class SecurityScoreDetailScreen extends StatelessWidget {
  final Map<String, dynamic> healthData;

  const SecurityScoreDetailScreen({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final int score = healthData['score'] ?? 0;
    final Map<String, dynamic> breakdown = healthData['breakdown'] ?? {};

    return ScreenScaffold(
      title: 'SECURITY HEALTH',
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                      // 1. Hero Score Section
                      _buildScoreHero(score),
                      SizedBox(height: 32),

                      Text(
                        'Security Breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // 2. Breakdown Items
                      _buildBreakdownItem(
                        context,
                        title: 'Device Security Scan',
                        points: breakdown['scan'] ?? 0,
                        maxPoints: 20,
                        icon: LucideIcons.scanLine,
                        description:
                            'Comprehensive analysis of installed apps and permissions.',
                        actionLabel: 'Scan Now',
                        onAction: () => Navigator.pushNamed(context, '/device-scan'),
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Email Verification',
                        points: breakdown['verification'] ?? 0,
                        maxPoints: 10,
                        icon: LucideIcons.mail,
                        description:
                            'Verify your email to secure your account recovery.',
                        actionLabel: 'Verify Now',
                        onAction: () {
                          // TODO: Navigate to verification or show info
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email verification flow coming soon.')),
                          );
                        },
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Premium Protection',
                        points: breakdown['subscription'] ?? 0,
                        maxPoints: 30,
                        icon: LucideIcons.shieldCheck,
                        description:
                            'Unlock advanced SMS and Call screening features.',
                        actionLabel: 'Upgrade Plan',
                        onAction: () => Navigator.pushNamed(context, '/subscription'),
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Profile Completeness',
                        points: breakdown['profile'] ?? 0,
                        maxPoints: 15,
                        icon: LucideIcons.user,
                        description:
                            'A complete profile helps verify your identity.',
                        actionLabel: 'Edit Profile',
                        onAction: () => Navigator.pop(context), // Root screen usually has profile
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Community Intelligence',
                        points: breakdown['reputation'] ?? 0,
                        maxPoints: 15,
                        icon: LucideIcons.star,
                        description:
                            'Earn points by contributing accurate scan results.',
                        actionLabel: 'Active',
                        onAction: () {},
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Security Logs',
                        points: 10,
                        maxPoints: 10,
                        icon: LucideIcons.fileText,
                        description:
                            'Regularly review your security audit history.',
                        actionLabel: 'View History',
                        onAction: () => Navigator.pushNamed(context, '/security-logs'),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildScoreHero(int score) {
    String status;
    Color statusColor;
    if (score >= 90) {
      status = 'EXCELLENT';
      statusColor = DesignTokens.colors.success;
    } else if (score >= 75) {
      status = 'GOOD';
      statusColor = DesignTokens.colors.primary;
    } else if (score >= 50) {
      status = 'ATTENTION';
      statusColor = DesignTokens.colors.warning;
    } else {
      status = 'CRITICAL';
      statusColor = DesignTokens.colors.error;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignTokens.spacing.xxxl),
      decoration: BoxDecoration(
        color: DesignTokens.colors.glassDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: DesignTokens.shadows.md,
      ),
      child: Column(
        children: [
          SecurityScoreGauge(
            score: score,
            color: statusColor,
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor, // Badge background is now the status color for better visibility
              borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white, // White text for better contrast
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Your security environment is currently $status',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context, {
    required String title,
    required int points,
    required int maxPoints,
    required IconData icon,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final bool isCompleted = points >= maxPoints;

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacing.lg),
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? DesignTokens.colors.accentGreen
                          : DesignTokens.colors.primary)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : icon,
                  color: isCompleted
                      ? DesignTokens.colors.accentGreen
                      : DesignTokens.colors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isCompleted ? 'Completed' : '$points / $maxPoints points',
                      style: TextStyle(
                        color: isCompleted
                            ? DesignTokens.colors.accentGreen
                            : Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight:
                            isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.colors.accentGreen,
                    padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
