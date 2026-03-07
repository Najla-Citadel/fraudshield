import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../constants/colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Health',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  AppColors.deepNavy, // Deep navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: AnimationLimiter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 32),

                      const Text(
                        'Security Breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

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

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHero(int score) {
    String status;
    Color statusColor;
    if (score >= 90) {
      status = 'EXCELLENT';
      statusColor = AppColors.accentGreen;
    } else if (score >= 70) {
      status = 'GOOD';
      statusColor = Colors.blue;
    } else if (score >= 50) {
      status = 'PROTECTED';
      statusColor = Colors.orange;
    } else {
      status = 'AT RISK';
      statusColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Slate
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 12),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? AppColors.accentGreen
                          : AppColors.primaryBlue)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : icon,
                  color: isCompleted
                      ? AppColors.accentGreen
                      : AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
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
                            ? AppColors.accentGreen
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
                    foregroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
