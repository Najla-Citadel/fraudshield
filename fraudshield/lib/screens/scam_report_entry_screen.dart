import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../l10n/app_localizations.dart';
import 'scam_reporting_screen.dart';
import 'report_history_screen.dart';

class ScamReportEntryScreen extends StatelessWidget {
  const ScamReportEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      title: l10n.scamReportTitle,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SecurityTipsCard(tips: [
              'Provide as much detail as possible to help the community.',
              'Screenshots of conversations or transactions are valuable evidence.',
              'Your reports help others avoid similar scams.',
            ]),
            SizedBox(height: 32),
            _buildEntryCard(
              context,
              title: 'Report New Scam',
              subtitle: 'Start the 4-step wizard to report a scammer.',
              icon: LucideIcons.shieldAlert,
              color: DesignTokens.colors.accentGreen,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScamReportingScreen()),
              ),
            ),
            SizedBox(height: 16),
            _buildEntryCard(
              context,
              title: 'My Report History',
              subtitle: 'View and track your previous submissions.',
              icon: LucideIcons.history,
              color: DesignTokens.colors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReportHistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = DesignTokens.colors;
    return GlassSurface(
      borderRadius: 24,
      onTap: onTap,
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTypography.h3,
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textLight.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: colors.textLight.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}
