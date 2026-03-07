import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/design_tokens.dart';
class SecurityHealthCard extends StatelessWidget {
  final int score;
  final String status;
  final VoidCallback onViewDetails;

  const SecurityHealthCard({
    super.key,
    required this.score,
    required this.status,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00C6A5), // Greenish
            DesignTokens.colors.primary, // Blue
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        boxShadow: DesignTokens.shadows.md,
      ),
      child: Stack(
        children: [
          // Background Sparkles/Icons (Simplified)
          Positioned(
            right: -20,
            top: -10,
            child: Opacity(
              opacity: 0.15,
              child: Icon(LucideIcons.shieldCheck, size: 140, color: Colors.white),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Security Health Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
