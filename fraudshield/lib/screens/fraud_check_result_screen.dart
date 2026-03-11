import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_divider.dart';
import '../widgets/glass_surface.dart';
import '../services/risk_evaluator.dart';
import '../l10n/app_localizations.dart';

class FraudCheckResultScreen extends StatelessWidget {
  final RiskResult result;
  final String searchValue;

  const FraudCheckResultScreen({
    super.key,
    required this.result,
    required this.searchValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    final isCritical = result.level == 'critical';
    final isHigh = result.level == 'high';
    final isMedium = result.level == 'medium';

    final Color riskColor = isCritical
        ? Colors.purple
        : isHigh
            ? const Color(0xFFEF4444)
            : isMedium
                ? const Color(0xFFF59E0B)
                : const Color(0xFF22C55E);

    final IconData riskIcon = isCritical
        ? Icons.security_rounded
        : isHigh
            ? Icons.gpp_bad_rounded
            : isMedium
                ? Icons.gpp_maybe_rounded
                : Icons.gpp_good_rounded;

    final String riskLabel = isCritical
        ? AppLocalizations.of(context)!.fraudCriticalThreat
        : isHigh
            ? AppLocalizations.of(context)!.fraudHighRisk
            : isMedium
                ? AppLocalizations.of(context)!.riskLevelSuspicious
                : AppLocalizations.of(context)!.fraudLooksSafe;

    return ScreenScaffold(
      title: AppLocalizations.of(context)!.fraudCheckResult,
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 450),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // Search Value Card
                GlassSurface(
                  borderRadius: 20,
                  padding: EdgeInsets.all(DesignTokens.spacing.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.search, color: colors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analyzed Input',
                              style: TextStyle(
                                color: colors.textLight.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              searchValue,
                              style: DesignTypography.bodyLg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Result Card
                GlassSurface(
                  borderRadius: 24,
                  padding: EdgeInsets.all(DesignTokens.spacing.xxl),
                  borderColor: riskColor.withValues(alpha: 0.3),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(riskIcon, color: riskColor, size: 32),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riskLabel,
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.fraudAiAnalysisResult,
                                  style: TextStyle(
                                    color: colors.textLight.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Score Meter
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 140,
                            width: 140,
                            child: CircularProgressIndicator(
                              value: result.score / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${result.score}',
                                style: TextStyle(
                                  color: colors.textLight,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: TextStyle(
                                  color: colors.textLight.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const AppDivider(height: 1),
                      const SizedBox(height: 24),
                      
                      // Reasons Header
                      Row(
                        children: [
                          Icon(LucideIcons.listChecks, color: colors.textLight, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Analysis Breakdown',
                            style: DesignTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reasons List
                      ...result.reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              reason.startsWith('✅')
                                  ? LucideIcons.checkCircle
                                  : reason.startsWith('⚠️')
                                      ? LucideIcons.alertTriangle
                                      : LucideIcons.info,
                              color: reason.startsWith('✅')
                                  ? colors.success
                                  : reason.startsWith('⚠️')
                                      ? colors.warning
                                      : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: colors.textLight.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Check Another',
                    onPressed: () => Navigator.pop(context),
                    variant: AppButtonVariant.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Home',
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    variant: AppButtonVariant.secondary,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
