import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/risk_evaluator.dart';
import '../services/recent_checks_service.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/tokens/design_tokens.dart';
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
  RiskResult? _lastResult;

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
      if (_detectedType != 'Phone / Bank' || _lastResult != null) {
        setState(() {
          _detectedType = 'Phone / Bank';
          _detectedIcon = Icons.payment_rounded;
          _lastResult = null;
        });
      }
      return;
    }

    if (_lastResult != null) {
      setState(() {
        _lastResult = null;
      });
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
    setState(() {
      _isLoading = false;
      _lastResult = result;
    });

    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: AppLocalizations.of(context)!.fraudCheckTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SecurityTipsCard(tips: [
              AppLocalizations.of(context)!.fraudTipOtp,
              AppLocalizations.of(context)!.fraudTipVerify,
              AppLocalizations.of(context)!.fraudTipReport,
            ]),
            const SizedBox(height: 28),
            GlassSurface(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.fraudSmartInput,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            letterSpacing: 0.8),
                      ),
                      if (_inputController.text.isNotEmpty &&
                          _detectedType == 'Payment')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignTokens.colors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Phone/Bank Detected',
                            style: TextStyle(
                                color: DesignTokens.colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.fraudHint,
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 15),
                      prefixIcon:
                          Icon(_detectedIcon, color: Colors.white38, size: 20),
                      suffixIcon: _inputController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.xCircle,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 18),
                              onPressed: () {
                                _inputController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
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
            if (_lastResult != null) ...[
              const SizedBox(height: 24),
              _buildResultSection(),
            ],
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.fraudRecentActivity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_recentChecks.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _saveClearedTimestamp();
                      setState(() => _recentChecks = []);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.4),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context)!.btnClear, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_lastResult == null) return const SizedBox.shrink();
    final isCritical = _lastResult!.level == 'critical';
    final isHigh = _lastResult!.level == 'high';
    final isMedium = _lastResult!.level == 'medium';
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

    return GlassSurface(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      borderColor: riskColor.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(riskIcon, color: riskColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riskLabel,
                      style: TextStyle(
                          color: riskColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context)!.fraudAiAnalysisResult,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_lastResult!.score}/100',
                  style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AppDivider(height: 1),
          const SizedBox(height: 16),
          ..._lastResult!.reasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          ? DesignTokens.colors.success
                          : reason.startsWith('⚠️')
                              ? DesignTokens.colors.warning
                              : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _lastResult!.score / 100,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              borderRadius: BorderRadius.circular(10),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isFetchingHistory) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AppLoadingIndicator(color: DesignTokens.colors.accentGreen),
        ),
      );
    }
    if (_recentChecks.isEmpty) {
      return const AppEmptyState(
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
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
        itemBuilder: (context, index) {
          final scan = _recentChecks[index];
          final value =
              (scan['target'] ?? scan['value'])?.toString() ?? 'Unknown';
          final dateStr = scan['createdAt']?.toString();
          if (dateStr == null) return const SizedBox.shrink();
          final date = DateTime.parse(dateStr);
          final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(date);
          final riskLevel =
              scan['riskLevel']?.toString().toUpperCase() ?? 'SAFE';
          final isSafe = riskLevel == 'SAFE';
          return ListTile(
            onTap: () => setState(() => _inputController.text = value),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSafe ? DesignTokens.colors.success : DesignTokens.colors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
