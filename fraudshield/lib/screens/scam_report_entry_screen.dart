import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            DesignTokens.colors.backgroundDark,
            Color(0xFF1E3A8A),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.scamReportTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SecurityTipsCard(tips: [
                'Provide as much detail as possible to help the community.',
                'Screenshots of conversations or transactions are valuable evidence.',
                'Your reports help others avoid similar scams.',
              ]),
              const SizedBox(height: 32),
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
              const SizedBox(height: 16),
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
    return GlassSurface(
      borderRadius: 24,
      onTap: onTap,
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}
