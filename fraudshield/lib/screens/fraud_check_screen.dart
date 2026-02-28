import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';
import '../services/recent_checks_service.dart';
import '../widgets/recent_checks_widget.dart';
import 'qr_detection_screen.dart';

class FraudCheckScreen extends StatefulWidget {
  const FraudCheckScreen({super.key});

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen>
    with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  
  String _detectedType = 'Phone / Bank';
  IconData _detectedIcon = Icons.payment_rounded;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
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

    String newType = 'Message';
    IconData newIcon = Icons.chat_bubble_outline_rounded;

    if (RegExp(r'^(http|https)://').hasMatch(text) || RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(text)) {
      newType = 'URL';
      newIcon = Icons.link_rounded;
    } else if (RegExp(r'^[\d\s+\-()]+$').hasMatch(text) && text.length >= 5) {
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

  Future<void> _uploadDocument() async {
    setState(() => _isLoading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'apk'],
        withData: false,
        withReadStream: false,
      );

      if (picked == null || picked.files.isEmpty || picked.files.first.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final filePath = picked.files.first.path!;
      final fileName = picked.files.first.name;
      final result = await RiskEvaluator.evaluateDocument(filePath);

      await RecentChecksService.addCheck(RecentCheckItem(
        type: 'Document',
        value: fileName,
        timestamp: DateTime.now(),
      ));

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckResultScreen(
            type: 'Document',
            value: fileName,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document scan failed: $e'), backgroundColor: Colors.red.shade700),
      );
    }
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
    if (_detectedType == 'URL') {
      result = await RiskEvaluator.evaluateUrl(_inputController.text.trim());
    } else if (_detectedType == 'Message') {
      result = await RiskEvaluator.analyzeMessage(_inputController.text.trim());
    } else {
      result = await RiskEvaluator.evaluatePayment(type: 'Payment', value: _inputController.text.trim());
    }

    final displayLabel = _detectedType == 'Payment' ? 'Phone / Bank' : _detectedType;

    await RecentChecksService.addCheck(RecentCheckItem(
      type: displayLabel,
      value: _inputController.text.trim(),
      timestamp: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckResultScreen(
          type: displayLabel,
          value: _inputController.text.trim(),
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: AppLocalizations.of(context)!.fraudCheckTitle,
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.fraudThinkScam,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.fraudAiDesc,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Smart Omnibar ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.fraudSmartInput,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 0.8),
                      ),
                      if (_inputController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _detectedType == 'Payment' ? 'Phone/Bank Detected' : '$_detectedType Detected',
                            style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
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
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 15),
                      prefixIcon: Icon(_detectedIcon, color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.upload_file_rounded,
                    label: AppLocalizations.of(context)!.fraudUploadFile,
                    subtext: AppLocalizations.of(context)!.fraudPdfApk,
                    onTap: _uploadDocument,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: AppLocalizations.of(context)!.fraudScanQr,
                    subtext: AppLocalizations.of(context)!.fraudCameraCheck,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QRDetectionScreen()));
                    },
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Check Now ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                text: _inputController.text.isEmpty 
                    ? AppLocalizations.of(context)!.fraudCheckNow 
                    : '${AppLocalizations.of(context)!.fraudAnalyze} ${_detectedType == 'Payment' ? 'Input' : _detectedType}',
                isLoading: _isLoading,
                onPressed: _check,
              ),
            ),
            const SizedBox(height: 28),

            // ── Safety Tips ──────────────────────────────
            _SafetyTipsCard(),

            const SizedBox(height: 32),

            // ── Recent Checks ────────────────────────────
            RecentChecksWidget(
              onCheckSelected: (item) {
                if (item.type == 'Document') {
                  // Cannot autofill Document type using omnibar text.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot reuse document uploads from history yet.')),
                  );
                  return;
                }
                setState(() {
                  _inputController.text = item.value;
                  // _onInputChanged will handle detecting correct type
                });
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Helper classes ──────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtext;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.subtext,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtext, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyTipsCard extends StatelessWidget {
  final _tips = const [
    _Tip(icon: Icons.lock_outline_rounded, text: 'Never share your OTP or banking details'),
    _Tip(icon: Icons.verified_outlined, text: 'Always verify official website URLs'),
    _Tip(icon: Icons.report_outlined, text: 'Report suspicious activity immediately'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.fraudStayProtected,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(t.icon, color: AppColors.accentGreen, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(t.text, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});
}

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

    final String riskLabel = isCritical ? 'Critical Threat' : isHigh ? 'High Risk' : isMedium ? 'Suspicious' : 'Looks Safe';
    final String riskSubtitle = isCritical
        ? 'Dangerous scam attempt identified. Block and report immediately.'
        : isHigh
            ? 'This appears to be fraudulent. Do not proceed.'
            : isMedium
                ? 'Proceed with caution and verify further.'
                : 'No threats found. Appears to be safe.';

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(AppLocalizations.of(context)!.fraudCheckResult, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Risk Badge ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
              ),
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
                    style: TextStyle(color: riskColor, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    riskSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Checked Value ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checked $type', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Risk Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                      Text(
                        '${result.score} / 100',
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.purpleAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('AI Deep Scan', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (result.scamType != null)
                      _infoRow('Scam category', result.scamType!.toUpperCase(), Colors.purpleAccent),
                    if (result.language != null)
                      _infoRow('Detected language', result.language!.toUpperCase(), Colors.blueAccent),
                    
                    if (result.highlightedPhrases.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('High-risk phrases detected:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.highlightedPhrases.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Text(p, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),

            if (result.redirectChain.isNotEmpty)
              Container(
                 width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      children: [
                        const Icon(Icons.alt_route_rounded, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('Redirect Path', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (int i=0; i<result.redirectChain.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${i+1}. ${result.redirectChain[i]}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Courier'),
                        ),
                      ),
                    if (result.finalUrl != null) ...[
                       const Divider(color: Colors.white12),
                       Text('Final Destination:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(result.finalUrl!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ),

            if (result.scamType != null || result.redirectChain.isNotEmpty)
              const SizedBox(height: 20),

            // ── Community Reports Badge ───────────────────
            // ── Document Scan Details (PDF/APK) ──────────
            if (type == 'Document' && (result.dangerousPermissions.isNotEmpty || result.extractedLinks.isNotEmpty || result.packageName != null || result.pageCount != null))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.document_scanner_outlined, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 8),
                      Text('Document Insights', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 16),
                    if (result.pageCount != null)
                      _infoRow('Page Count', '${result.pageCount} pages', Colors.white70),
                    if (result.extractedLinks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Embedded Links (${result.extractedLinks.length}):', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      const SizedBox(height: 8),
                      ...result.extractedLinks.take(5).map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('🔗 $l', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontFamily: 'Courier')),
                      )),
                      if (result.extractedLinks.length > 5)
                        Text('...and ${result.extractedLinks.length - 5} more', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    ],
                    if (result.packageName != null)
                      _infoRow('Package Name', result.packageName!, Colors.blueAccent),
                    if (result.dangerousPermissions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Dangerous Permissions:', style: TextStyle(color: Colors.red.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...result.dangerousPermissions.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        ]),
                      )),
                    ],
                    if (result.sha256 != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      Text('SHA-256:', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(result.sha256!, style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Courier')),
                    ],
                  ],
                ),
              ),

            if (result.communityReports > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text('Community Insights', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reports Found', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                        Text('${result.communityReports}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Verified by Others', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                        Text('${result.verifiedReports}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    if (result.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.categories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                          ),
                        )).toList(),
                      ),
                    ]
                  ],
                ),
              ),
              
            if (result.communityReports > 0)
              const SizedBox(height: 20),

            // ── Verification Sources ──────────────────────
            if (result.sources.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.policy_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('Verification Sources', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: result.sources.map((source) {
                        if (source == 'ccid') {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 16),
                                const SizedBox(width: 6),
                                const Text('PDRM Semak Mule', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        } else if (source == 'community') {
                          return _buildSourcePill('FraudShield Community', Icons.people_alt_outlined, AppColors.primaryBlue);
                        } else {
                          return _buildSourcePill(source, Icons.source_outlined, Colors.grey);
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analysis Details', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 14),
                    ...result.reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chevron_right_rounded, color: riskColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4))),
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
                      const SnackBar(content: Text('Calling NSRC (997) - Direct Emergency Line')),
                    );
                  },
                  icon: const Icon(Icons.local_police_rounded, color: Colors.white),
                  label: const Text('Call NSRC (997)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  backgroundColor: (isHigh || isCritical) ? const Color(0xFF1E293B) : AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text((isHigh || isCritical) ? 'Go Back' : 'Check Another', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
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
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }
}
