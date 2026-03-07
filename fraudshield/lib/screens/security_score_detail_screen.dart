import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'subscription_screen.dart';

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
                        title: 'Email Verification',
                        points: breakdown['verification'] ?? 0,
                        maxPoints: 20,
                        icon: LucideIcons.mail,
                        description:
                            'Verify your email to secure your account recovery.',
                        actionLabel: 'Verify Now',
                        onAction: () {
                          // Navigate to verification or show info
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
                        onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen())),
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
                        onAction: () => Navigator.pop(context),
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Community Reputation',
                        points: breakdown['reputation'] ?? 0,
                        maxPoints: 15,
                        icon: LucideIcons.star,
                        description:
                            'Earn points by contributing accurate scan results.',
                        actionLabel: 'Learn More',
                        onAction: () {},
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Reporting Activity',
                        points: breakdown['activity'] ?? 0,
                        maxPoints: 10,
                        icon: LucideIcons.flag,
                        description:
                            'Active reporting helps protect the community.',
                        actionLabel: 'Report Now',
                        onAction: () {},
                      ),
                      _buildBreakdownItem(
                        context,
                        title: 'Alert Monitoring',
                        points: breakdown['alerts'] ?? 0,
                        maxPoints: 10,
                        icon: LucideIcons.bell,
                        description:
                            'Enable real-time push notifications for threats.',
                        actionLabel: 'Enable Alerts',
                        onAction: () {},
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
      statusColor = DesignTokens.colors.accentGreen;
    } else if (score >= 70) {
      status = 'GOOD';
      statusColor = DesignTokens.colors.primary;
    } else if (score >= 50) {
      status = 'PROTECTED';
      statusColor = DesignTokens.colors.warning;
    } else {
      status = 'AT RISK';
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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: AppLoadingIndicator.center(),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'OF 100',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your security environment is currently $status',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
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
