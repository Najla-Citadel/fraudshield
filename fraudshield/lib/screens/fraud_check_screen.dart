import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../widgets/adaptive_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../services/api_service.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/components/app_button.dart';

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
            final type = tx['checkType']?.toString().toUpperCase() ?? '';
            final isPayment =
                type == 'PHONE' || type == 'BANK' || type == 'MANUAL';
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
                        label: '', 
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
      return Center(
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(LucideIcons.history,
                size: 64, color: Colors.white.withOpacity(0.1)),
            SizedBox(height: 12),
            Text(
              'No recent activity',
              style: DesignTypography.bodySm.copyWith(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentChecks.map((scan) {
        final value = (scan['target'] ?? scan['value'])?.toString() ?? 'Unknown';
        final dateStr = scan['createdAt']?.toString();
        if (dateStr == null) return SizedBox.shrink();
        final date = DateTime.parse(dateStr);
        final formattedDate = _formatTimestamp(date);
        
        final riskLevel = scan['status']?.toString().toUpperCase() ?? 'SAFE';
        final isSafe = riskLevel == 'SAFE';
        final accentColor = isSafe ? DesignTokens.colors.success : DesignTokens.colors.error;

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacing.md),
          child: GlassSurface(
            onTap: () {
              setState(() => _inputController.text = value);
              _check();
            },
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            borderRadius: 20,
            accentColor: accentColor,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSafe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTypography.labelMd,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$formattedDate • $riskLevel',
                        style: DesignTypography.caption.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    color: Colors.white.withOpacity(0.2), size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${ts.day} ${_getMonth(ts.month)}';
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
