import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../services/risk_evaluator.dart';
import '../services/recent_checks_service.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../widgets/adaptive_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_empty_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../design_system/components/app_divider.dart';
import '../design_system/components/app_snackbar.dart';

class FraudCheckScreen extends StatefulWidget {
  final String? initialType;
  const FraudCheckScreen({super.key, this.initialType});

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen>
    with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  bool _isLoading = false;

  String _detectedType = 'Phone / Bank';
  IconData _detectedIcon = Icons.payment_rounded;
  List<dynamic> _recentChecks = [];
  bool _isFetchingHistory = true;
  DateTime? _lastClearedAt;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);

    if (widget.initialType != null) {
      _detectedType =
          widget.initialType == 'PHONE' || widget.initialType == 'BANK'
              ? 'Payment'
              : widget.initialType!;

      if (_detectedType == 'Payment') {
        _detectedIcon = Icons.payment_rounded;
      } else if (_detectedType == 'DOC') {
        _detectedIcon = Icons.upload_file_rounded;
      }
    }

    _loadClearedTimestamp().then((_) => _fetchHistory());
  }

  Future<void> _loadClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('fraud_history_cleared_at');
    if (ts != null) {
      if (mounted) setState(() => _lastClearedAt = DateTime.parse(ts));
    }
  }

  Future<void> _saveClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('fraud_history_cleared_at', now.toIso8601String());
    if (mounted) setState(() => _lastClearedAt = now);
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.instance.getTransactionJournal();
      if (mounted) {
        setState(() {
          List<dynamic> allResults = response['results'] ?? [];
          List<dynamic> filtered = allResults.where((tx) {
            final type = tx['type']?.toString().toUpperCase() ?? '';
            final isPayment =
                type == 'PAYMENT' || type == 'PHONE' || type == 'BANK';
            if (!isPayment) return false;

            if (_lastClearedAt != null) {
              final txDate = DateTime.parse(tx['createdAt']);
              return txDate.isAfter(_lastClearedAt!);
            }
            return true;
          }).toList();

          _recentChecks = filtered;
          _isFetchingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching fraud history: $e');
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  void _onInputChanged() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      if (_detectedType != 'Phone / Bank') {
        setState(() {
          _detectedType = 'Phone / Bank';
          _detectedIcon = Icons.payment_rounded;
        });
      }
      return;
    }

    String newType = 'Phone / Bank';
    IconData newIcon = Icons.payment_rounded;

    if (RegExp(r'^[\d\s+\-()]+$').hasMatch(text) && text.length >= 5) {
      newType = 'Payment';
      newIcon = Icons.payment_rounded;
    }

    if (newType != _detectedType) {
      setState(() {
        _detectedType = newType;
        _detectedIcon = newIcon;
      });
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_inputController.text.isEmpty) {
      AppSnackBar.showError(context, AppLocalizations.of(context)!.fraudEnterContentPrompt);
      return;
    }

    setState(() => _isLoading = true);

    RiskResult result = await RiskEvaluator.evaluatePayment(
        type: 'Payment', value: _inputController.text.trim());

    final displayLabel =
        _detectedType == 'Payment' ? 'Phone / Bank' : _detectedType;

    await RecentChecksService.addCheck(RecentCheckItem(
      type: displayLabel,
      value: _inputController.text.trim(),
      timestamp: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/fraud-check-result',
        arguments: {
          'result': result,
          'searchValue': _inputController.text.trim(),
        },
      );
    }

    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    
    return ScreenScaffold(
      title: AppLocalizations.of(context)!.fraudCheckTitle,
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                SecurityTipsCard(tips: [
                  AppLocalizations.of(context)!.fraudTipOtp,
                  AppLocalizations.of(context)!.fraudTipVerify,
                  AppLocalizations.of(context)!.fraudTipReport,
                ]),
                const SizedBox(height: 28),
                
                // Smart Input Area
                GlassSurface(
                  borderRadius: 24,
                  padding: EdgeInsets.all(DesignTokens.spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.fraudSmartInput,
                            style: TextStyle(
                              color: colors.textLight.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (_detectedType == 'Payment' && _inputController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.fraudPhoneBankDetected,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AdaptiveTextField(
                        controller: _inputController,
                        label: '', // Label hidden to match screenshot
                        placeholder: AppLocalizations.of(context)!.fraudHint,
                        maxLines: 4,
                        prefixIcon: _detectedIcon,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        onChanged: (_) => setState(() {}),
                        suffixIcon: _inputController.text.isNotEmpty ? LucideIcons.xCircle : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _inputController.text.isEmpty
                        ? AppLocalizations.of(context)!.fraudCheckNow
                        : '${AppLocalizations.of(context)!.fraudAnalyze} Input',
                    isLoading: _isLoading,
                    onPressed: _check,
                    variant: AppButtonVariant.primary,
                  ),
                ),
                
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.fraudRecentActivity,
                      style: DesignTypography.h3.copyWith(color: colors.textLight),
                    ),
                    if (_recentChecks.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _saveClearedTimestamp();
                          setState(() => _recentChecks = []);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textLight.withValues(alpha: 0.4),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.btnClear,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecentActivity(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecentActivity() {
    if (_isFetchingHistory) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacing.xxxl),
          child: AppLoadingIndicator(color: DesignTokens.colors.accentGreen),
        ),
      );
    }
    if (_recentChecks.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.history,
        title: 'No recent activity',
        description: 'Your check history will appear here once you start analyzing phone numbers or bank accounts.',
        iconSize: 48,
      );
    }
    return GlassSurface(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentChecks.length,
        separatorBuilder: (context, index) =>
            AppDivider(),
        itemBuilder: (context, index) {
          final scan = _recentChecks[index];
          final value =
              (scan['target'] ?? scan['value'])?.toString() ?? 'Unknown';
          final dateStr = scan['createdAt']?.toString();
          if (dateStr == null) return SizedBox.shrink();
          final date = DateTime.parse(dateStr);
          final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(date);
          final riskLevel =
              scan['riskLevel']?.toString().toUpperCase() ?? 'SAFE';
          final isSafe = riskLevel == 'SAFE';
          return ListTile(
            onTap: () => setState(() => _inputController.text = value),
            contentPadding:
                EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.sm),
            leading: Container(
              padding: EdgeInsets.all(DesignTokens.spacing.sm),
              decoration: BoxDecoration(
                color: (isSafe ? DesignTokens.colors.success : DesignTokens.colors.error)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: isSafe ? DesignTokens.colors.success : DesignTokens.colors.error,
                size: 20,
              ),
            ),
            title: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              timeStr,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: DesignTokens.spacing.xs),
              decoration: BoxDecoration(
                color: (isSafe ? DesignTokens.colors.success : DesignTokens.colors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: Text(
                riskLevel,
                style: TextStyle(
                  color: isSafe ? DesignTokens.colors.success : DesignTokens.colors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
