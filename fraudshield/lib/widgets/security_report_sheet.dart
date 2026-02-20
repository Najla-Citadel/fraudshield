import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SecurityReportSheet extends StatefulWidget {
  final int score;
  final bool isSubscribed;
  final bool profileComplete;
  final int activeDefensesCount;
  final VoidCallback onFixPremium;
  final VoidCallback onUpdateProfile;
  final VoidCallback onEnableDefenses;

  const SecurityReportSheet({
    super.key,
    required this.score,
    required this.isSubscribed,
    required this.profileComplete,
    required this.activeDefensesCount,
    required this.onFixPremium,
    required this.onUpdateProfile,
    required this.onEnableDefenses,
  });

  @override
  State<SecurityReportSheet> createState() => _SecurityReportSheetState();
}

class _SecurityReportSheetState extends State<SecurityReportSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(widget.score).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getScoreColor(widget.score)),
                ),
                child: Text(
                  'Score: ${widget.score}/100',
                  style: TextStyle(
                    color: _getScoreColor(widget.score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Profile Security
          _buildCheckItem(
            icon: Icons.person,
            title: 'Profile Security',
            subtitle: widget.profileComplete 
              ? 'Profile information is up to date.'
              : 'Complete your profile to improve security.',
            isSafe: widget.profileComplete,
            actionLabel: widget.profileComplete ? null : 'UPDATE',
            onAction: widget.onUpdateProfile,
          ),
          
          // 2. Active Defenses
          _buildCheckItem(
            icon: Icons.shield,
            title: 'Active Defenses',
            subtitle: '${widget.activeDefensesCount} protection layers active.',
            isSafe: widget.activeDefensesCount > 0,
            actionLabel: widget.activeDefensesCount > 0 ? null : 'ENABLE',
            onAction: widget.onEnableDefenses,
          ),

          // 3. Premium Protection
          _buildCheckItem(
            icon: Icons.diamond,
            title: 'Premium Protection',
            subtitle: widget.isSubscribed 
              ? 'Advanced AI shields are active.' 
              : 'Upgrade to unlock full protection.',
            isSafe: widget.isSubscribed,
            actionLabel: widget.isSubscribed ? null : 'UNLOCK',
            onAction: widget.onFixPremium,
            isLocked: !widget.isSubscribed,
          ),

          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.accentGreen;
    if (score >= 70) return Colors.amber;
    return Colors.redAccent;
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSafe,
    String? actionLabel,
    VoidCallback? onAction,
    bool isLocked = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSafe 
                ? AppColors.accentGreen.withOpacity(0.1) 
                : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSafe ? AppColors.accentGreen : Colors.redAccent,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock, size: 14, color: Colors.amber),
                  ],
                ],
              ),
            ),
          if (actionLabel == null && isSafe)
             const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
        ],
      ),
    );
  }
}
