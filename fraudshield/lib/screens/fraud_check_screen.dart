import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_button.dart';
import '../services/recent_checks_service.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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
          // Filter for payment/phone/bank types and apply local clearing
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter content to check'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    RiskResult result;
    result = await RiskEvaluator.evaluatePayment(
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

    // Refresh history after check
    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              AppColors.deepNavy,
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
              AppLocalizations.of(context)!.fraudCheckTitle,
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
                // ── Security Tips ──────────────────────────────
                SecurityTipsCard(tips: [
                  AppLocalizations.of(context)!.fraudTipOtp,
                  AppLocalizations.of(context)!.fraudTipVerify,
                  AppLocalizations.of(context)!.fraudTipReport,
                ]),
                const SizedBox(height: 28),

                // ── Smart Omnibar ───────────────────────────────
                GlassSurface(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  accentColor: AppColors.primaryBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.fraudSmartInput,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                letterSpacing: 0.8),
                          ),
                          if (_inputController.text.isNotEmpty &&
                              _detectedType == 'Payment')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Phone/Bank Detected',
                                style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _inputController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.fraudHint,
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 15),
                          prefixIcon: Icon(_detectedIcon,
                              color: Colors.white38, size: 20),
                          suffixIcon: _inputController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(LucideIcons.xCircle,
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      size: 18),
                                  onPressed: () {
                                    _inputController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
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

                // ── Check Now ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: AdaptiveButton(
                    text: _inputController.text.isEmpty
                        ? AppLocalizations.of(context)!.fraudCheckNow
                        : '${AppLocalizations.of(context)!.fraudAnalyze} Input',
                    isLoading: _isLoading,
                    onPressed: _check,
                  ),
                ),
                if (_lastResult != null) ...[
                  const SizedBox(height: 24),
                  _buildResultSection(),
                ],
                const SizedBox(height: 28),

                const SizedBox(height: 32),

                // ── Recent Activity Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
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
                          foregroundColor: Colors.white.withValues(alpha: 0.4),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child:
                            const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildRecentActivity(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ));
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
        ? 'Critical Threat'
        : isHigh
            ? 'High Risk'
            : isMedium
                ? 'Suspicious'
                : 'Looks Safe';

    return GlassSurface(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      borderColor: riskColor.withValues(alpha: 0.3),
      accentColor: AppColors.primaryBlue,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI Analysis Result',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_lastResult!.score}/100',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
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
                          ? Colors.green
                          : reason.startsWith('⚠️')
                              ? Colors.orange
                              : Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
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
              backgroundColor: Colors.white.withValues(alpha: 0.05),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_recentChecks.isEmpty) {
      return GlassSurface(
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        accentColor: AppColors.primaryBlue,
        child: Column(
          children: [
            Icon(LucideIcons.history,
                color: AppColors.greyText.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            const Text(
              'No recent activity',
              style: TextStyle(color: AppColors.greyText),
            ),
          ],
        ),
      );
    }

    return GlassSurface(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      accentColor: AppColors.primaryBlue,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentChecks.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        itemBuilder: (context, index) {
          final scan = _recentChecks[index];
          // Use 'target' if 'value' is missing, matching URL screen logic
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
            onTap: () {
              setState(() {
                _inputController.text = value;
              });
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: isSafe ? AppColors.accentGreen : Colors.red,
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
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                riskLevel,
                style: TextStyle(
                  color: isSafe ? AppColors.accentGreen : Colors.red,
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

// ── Helper classes ──────────────────────────────────

// ── Result Screen ────────────────────────────────────────────────────────────

class CheckResultScreen extends StatelessWidget {
  final String type;
  final String value;
  final RiskResult result;

  const CheckResultScreen({
    super.key,
    required this.type,
    required this.value,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
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
        ? 'Critical Threat'
        : isHigh
            ? 'High Risk'
            : isMedium
                ? 'Suspicious'
                : 'Looks Safe';
    final String riskSubtitle = isCritical
        ? 'Dangerous scam attempt identified. Block and report immediately.'
        : isHigh
            ? 'This appears to be fraudulent. Do not proceed.'
            : isMedium
                ? 'Proceed with caution and verify further.'
                : 'No threats found. Appears to be safe.';

    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              AppColors.deepNavy,
              Color(0xFF1E3A8A),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(AppLocalizations.of(context)!.fraudCheckResult,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Risk Badge ────────────────────────────────
                GlassSurface(
                  borderRadius: 24,
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  borderColor: riskColor.withValues(alpha: 0.3),
                  accentColor: AppColors.primaryBlue,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(riskIcon, color: riskColor, size: 52),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        riskLabel,
                        style: TextStyle(
                            color: riskColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        riskSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Checked Value ─────────────────────────────
                GlassSurface(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(20),
                  accentColor: AppColors.primaryBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Checked $type',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const Divider(color: Colors.white12, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Risk Score',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14)),
                          Text(
                            '${result.score} / 100',
                            style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: result.score / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Advanced Analysis (if Quishing/NLP) ────────
                if (result.scamType != null || result.language != null)
                  GlassSurface(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(20),
                    accentColor: AppColors.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined,
                                color: Colors.purpleAccent, size: 20),
                            const SizedBox(width: 8),
                            Text('AI Deep Scan',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (result.scamType != null)
                          _infoRow(
                              'Scam category',
                              result.scamType!.toUpperCase(),
                              Colors.purpleAccent),
                        if (result.language != null)
                          _infoRow(
                              'Detected language',
                              result.language!.toUpperCase(),
                              Colors.blueAccent),
                        if (result.highlightedPhrases.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('High-risk phrases detected:',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: result.highlightedPhrases
                                .map((p) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.red
                                                .withValues(alpha: 0.2)),
                                      ),
                                      child: Text(p,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                if (result.redirectChain.isNotEmpty)
                  GlassSurface(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(20),
                    accentColor: AppColors.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alt_route_rounded,
                                color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Text('Redirect Path',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        for (int i = 0; i < result.redirectChain.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${i + 1}. ${result.redirectChain[i]}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontFamily: 'Courier'),
                            ),
                          ),
                        if (result.finalUrl != null) ...[
                          const Divider(color: Colors.white12),
                          Text('Final Destination:',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(result.finalUrl!,
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ),

                if (result.scamType != null || result.redirectChain.isNotEmpty)
                  const SizedBox(height: 20),

                // ── Community Reports Badge ───────────────────
                // ── Document Scan Details (PDF/APK) ──────────
                if (type == 'Document' &&
                    (result.dangerousPermissions.isNotEmpty ||
                        result.extractedLinks.isNotEmpty ||
                        result.packageName != null ||
                        result.pageCount != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GlassSurface(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(20),
                      accentColor: AppColors.primaryBlue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.document_scanner_outlined,
                                color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 8),
                            Text('Document Insights',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ]),
                          const SizedBox(height: 16),
                          if (result.pageCount != null)
                            _infoRow('Page Count', '${result.pageCount} pages',
                                Colors.white70),
                          if (result.extractedLinks.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                                'Embedded Links (${result.extractedLinks.length}):',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            ...result.extractedLinks.take(5).map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('🔗 $l',
                                      style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 11,
                                          fontFamily: 'Courier')),
                                )),
                            if (result.extractedLinks.length > 5)
                              Text(
                                  '...and ${result.extractedLinks.length - 5} more',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      fontSize: 11)),
                          ],
                          if (result.packageName != null)
                            _infoRow('Package Name', result.packageName!,
                                Colors.blueAccent),
                          if (result.dangerousPermissions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Dangerous Permissions:',
                                style: TextStyle(
                                    color: Colors.red.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...result.dangerousPermissions.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.redAccent, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(p,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12))),
                                  ]),
                                )),
                          ],
                          if (result.sha256 != null) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Text('SHA-256:',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(result.sha256!,
                                style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontFamily: 'Courier')),
                          ],
                        ],
                      ),
                    ),
                  ),

                if (result.communityReports > 0) const SizedBox(height: 20),

                // ── Verification Sources ──────────────────────
                if (result.sources.isNotEmpty) ...[
                  GlassSurface(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(20),
                    accentColor: AppColors.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.policy_outlined,
                                color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Text('Verification Sources',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: result.sources.map((source) {
                            if (source == 'ccid') {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blueAccent
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded,
                                        color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 6),
                                    const Text('PDRM Semak Mule',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            } else if (source == 'community') {
                              return _buildSourcePill(
                                  'FraudShield Community',
                                  Icons.people_alt_outlined,
                                  AppColors.primaryBlue);
                            } else {
                              return _buildSourcePill(
                                  source, Icons.source_outlined, Colors.grey);
                            }
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Reasons ───────────────────────────────────
                if (result.reasons.isNotEmpty)
                  GlassSurface(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(20),
                    accentColor: AppColors.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analysis Details',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 14),
                        ...result.reasons.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.chevron_right_rounded,
                                      color: riskColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(r,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 13,
                                              height: 1.4))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Quick Actions ───────────────────────────────
                if (isHigh || isCritical) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Calling NSRC (997) - Direct Emergency Line')),
                        );
                      },
                      icon: const Icon(Icons.local_police_rounded,
                          color: Colors.white),
                      label: const Text('Call NSRC (997)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isHigh || isCritical)
                          ? const Color(0xFF1E293B)
                          : AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                        (isHigh || isCritical) ? 'Go Back' : 'Check Another',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSourcePill(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }
}
