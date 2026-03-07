import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';

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
      decoration: BoxDecoration(
        color: DesignTokens.colors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: DesignTokens.shadows.lg,
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
              Text(
                AppLocalizations.of(context)!.homeSecurityReport,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(widget.score).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
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
            title: AppLocalizations.of(context)!.homeProfileSecurity,
            subtitle: widget.profileComplete 
              ? AppLocalizations.of(context)!.homeProfileSafeDesc
              : AppLocalizations.of(context)!.homeProfileAtRiskDesc,
            isSafe: widget.profileComplete,
            actionLabel: widget.profileComplete ? null : AppLocalizations.of(context)!.btnUpdate,
            onAction: widget.onUpdateProfile,
          ),
          
          // 2. Active Defenses
          _buildCheckItem(
            icon: Icons.shield,
            title: AppLocalizations.of(context)!.homeActiveDefenses,
            subtitle: '${widget.activeDefensesCount} ${AppLocalizations.of(context)!.homeActiveDefensesDesc}',
            isSafe: widget.activeDefensesCount > 0,
            actionLabel: widget.activeDefensesCount > 0 ? null : AppLocalizations.of(context)!.btnEnable,
            onAction: widget.onEnableDefenses,
          ),

          // 3. Premium Protection
          _buildCheckItem(
            icon: Icons.diamond,
            title: AppLocalizations.of(context)!.homePremiumProtection,
            subtitle: widget.isSubscribed 
              ? AppLocalizations.of(context)!.homePremiumAdvancedDesc 
              : AppLocalizations.of(context)!.homePremiumUpgradeDesc,
            isSafe: widget.isSubscribed,
            actionLabel: widget.isSubscribed ? null : AppLocalizations.of(context)!.btnUnlock,
            onAction: widget.onFixPremium,
            isLocked: !widget.isSubscribed,
          ),

          const SizedBox(height: 32),
          
          AppButton(
            onPressed: () => Navigator.pop(context),
            label: AppLocalizations.of(context)!.btnDone,
            variant: AppButtonVariant.primary,
            width: double.infinity,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return DesignTokens.colors.accentGreen;
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
                            ? DesignTokens.colors.accentGreen.withOpacity(0.1) 
                            : Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                        ),
                        child: Icon(
                          icon,
                          color: isSafe ? DesignTokens.colors.accentGreen : Colors.redAccent,
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
             Icon(Icons.check_circle, color: DesignTokens.colors.accentGreen, size: 20),
        ],
      ),
    );
  }
}
