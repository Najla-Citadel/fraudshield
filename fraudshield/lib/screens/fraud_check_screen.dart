import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
>>>>>>> dev-ui2
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';
import '../services/recent_checks_service.dart';
import '../widgets/recent_checks_widget.dart';
<<<<<<< HEAD

class FraudCheckScreen extends StatefulWidget {
  const FraudCheckScreen({super.key});
=======
import 'qr_detection_screen.dart';

class FraudCheckScreen extends StatefulWidget {
  final String? initialType;
  const FraudCheckScreen({super.key, this.initialType});
>>>>>>> dev-ui2

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen>
    with SingleTickerProviderStateMixin {
<<<<<<< HEAD
  int _selectedIndex = 0;
  final _inputController = TextEditingController();
  bool _isLoading = false;

  static const _tabs = [
    _TabItem(label: 'Phone / Bank', icon: Icons.payment_rounded, hint: 'Bank acc, phone, or merchant', type: 'Payment'),
    _TabItem(label: 'URL', icon: Icons.link_rounded, hint: 'e.g. https://bank.com', type: 'URL'),
    _TabItem(label: 'Document', icon: Icons.description_outlined, hint: 'Upload a file', type: 'Document'),
  ];

  @override
  void dispose() {
=======
  final _inputController = TextEditingController();
  bool _isLoading = false;
  
  String _detectedType = 'Phone / Bank';
  IconData _detectedIcon = Icons.payment_rounded;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    
    if (widget.initialType != null) {
      _detectedType = widget.initialType == 'PHONE' || widget.initialType == 'BANK' 
          ? 'Payment' 
          : widget.initialType!;
          
      if (_detectedType == 'Payment') {
        _detectedIcon = Icons.payment_rounded;
      } else if (_detectedType == 'URL') {
        _detectedIcon = Icons.link_rounded;
      } else if (_detectedType == 'DOC') {
        _detectedIcon = Icons.upload_file_rounded;
      }
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
>>>>>>> dev-ui2
    _inputController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  Future<void> _check() async {
    final tab = _tabs[_selectedIndex];

    if (_inputController.text.isEmpty && tab.type != 'Document') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a ${tab.label}'),
=======
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
>>>>>>> dev-ui2
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    RiskResult result;
<<<<<<< HEAD
    if (tab.type == 'Document') {
      await Future.delayed(const Duration(milliseconds: 400));
      result = RiskResult(level: 'low', score: 10, reasons: ['No malware found', 'File appears legitimate']);
    } else if (tab.type == 'URL') {
      // Use async API-backed evaluation for URLs
      result = await RiskEvaluator.evaluateUrl(_inputController.text.trim());
    } else {
      // Unified payment (phone/bank/merchant) pre-check
      result = await RiskEvaluator.evaluatePayment(type: 'Payment', value: _inputController.text.trim());
    }

    // Save to recent checks
    if (tab.type != 'Document') {
      await RecentChecksService.addCheck(RecentCheckItem(
        type: tab.label, // Use label (Phone, URL, Bank Acc) to match UI
        value: _inputController.text.trim(),
        timestamp: DateTime.now(),
      ));
    }
=======
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
>>>>>>> dev-ui2

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckResultScreen(
<<<<<<< HEAD
          type: tab.label,
          value: tab.type == 'Document' ? 'Uploaded File' : _inputController.text.trim(),
=======
          type: displayLabel,
          value: _inputController.text.trim(),
>>>>>>> dev-ui2
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final tab = _tabs[_selectedIndex];

    return AdaptiveScaffold(
      title: 'Fraud Check',
=======
    return AdaptiveScaffold(
      title: AppLocalizations.of(context)!.fraudCheckTitle,
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                    color: AppColors.primaryBlue.withOpacity(0.15),
=======
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
>>>>>>> dev-ui2
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
<<<<<<< HEAD
                      'Think it might be a scam?',
=======
                      AppLocalizations.of(context)!.fraudThinkScam,
>>>>>>> dev-ui2
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
<<<<<<< HEAD
                      'Instant AI-powered fraud detection',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
=======
                      AppLocalizations.of(context)!.fraudAiDesc,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
>>>>>>> dev-ui2
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

<<<<<<< HEAD
            // ── Tab Chips ────────────────────────────────
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final selected = i == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIndex = i;
                      _inputController.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryBlue : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected ? AppColors.primaryBlue : Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabs[i].icon, size: 15, color: selected ? Colors.white : Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // ── Input Card ───────────────────────────────
=======
            // ── Smart Omnibar ───────────────────────────────
>>>>>>> dev-ui2
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
                border: Border.all(color: Colors.white.withOpacity(0.07)),
=======
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
>>>>>>> dev-ui2
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< HEAD
                  Text(
                    'Enter ${tab.label}',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  if (tab.type == 'Document')
                    _DocumentUploadHint()
                  else
                    TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      keyboardType: tab.type == 'Phone No'
                          ? TextInputType.phone
                          : tab.type == 'URL'
                              ? TextInputType.url
                              : TextInputType.number,
                      decoration: InputDecoration(
                        hintText: tab.hint,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
                        prefixIcon: Icon(tab.icon, color: Colors.white38, size: 20),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
=======
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
>>>>>>> dev-ui2
                ],
              ),
            ),
            const SizedBox(height: 20),

<<<<<<< HEAD
=======
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

>>>>>>> dev-ui2
            // ── Check Now ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
<<<<<<< HEAD
                text: 'Check Now',
=======
                text: _inputController.text.isEmpty 
                    ? AppLocalizations.of(context)!.fraudCheckNow 
                    : '${AppLocalizations.of(context)!.fraudAnalyze} ${_detectedType == 'Payment' ? 'Input' : _detectedType}',
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                // Find index of tab
                int index = 0;
                for (int i = 0; i < _tabs.length; i++) {
                  // _tabs[i].label is 'Phone', 'URL' etc. item.type should match
                  if (_tabs[i].label == item.type) {
                    index = i;
                    break;
                  }
                }
                
                setState(() {
                  _selectedIndex = index;
                  _inputController.text = item.value;
=======
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
>>>>>>> dev-ui2
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

<<<<<<< HEAD
class _TabItem {
  final String label;
  final IconData icon;
  final String hint;
  final String type;
  const _TabItem({required this.label, required this.icon, required this.hint, required this.type});
}

class _DocumentUploadHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File upload coming soon')),
      ),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_outlined, color: Colors.white38, size: 28),
              const SizedBox(height: 6),
              Text('Tap to upload a document', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ],
          ),
=======
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
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        border: Border.all(color: Colors.white.withOpacity(0.06)),
=======
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
>>>>>>> dev-ui2
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
<<<<<<< HEAD
                'Stay Protected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
=======
                AppLocalizations.of(context)!.fraudStayProtected,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                Expanded(child: Text(t.text, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13))),
=======
                Expanded(child: Text(t.text, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13))),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
    final isHigh = result.level == 'high';
    final isMedium = result.level == 'medium';

    final Color riskColor = isHigh
        ? const Color(0xFFEF4444)
        : isMedium
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    final IconData riskIcon = isHigh
        ? Icons.gpp_bad_rounded
        : isMedium
            ? Icons.gpp_maybe_rounded
            : Icons.gpp_good_rounded;

    final String riskLabel = isHigh ? 'High Risk' : isMedium ? 'Suspicious' : 'Looks Safe';
    final String riskSubtitle = isHigh
        ? 'This appears to be fraudulent. Do not proceed.'
        : isMedium
            ? 'Proceed with caution and verify further.'
            : 'No threats found. Appears to be safe.';
=======
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
>>>>>>> dev-ui2

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
<<<<<<< HEAD
        title: const Text('Check Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
=======
        title: Text(AppLocalizations.of(context)!.fraudCheckResult, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: riskColor.withOpacity(0.3), width: 1.5),
=======
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
>>>>>>> dev-ui2
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
<<<<<<< HEAD
                      color: riskColor.withOpacity(0.15),
=======
                      color: riskColor.withValues(alpha: 0.15),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
=======
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                border: Border.all(color: Colors.white.withOpacity(0.06)),
=======
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
>>>>>>> dev-ui2
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< HEAD
                  Text('Checked $type', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
=======
                  Text('Checked $type', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
>>>>>>> dev-ui2
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
<<<<<<< HEAD
                      Text('Risk Score', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
=======
                      Text('Risk Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                      backgroundColor: Colors.white.withOpacity(0.08),
=======
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
>>>>>>> dev-ui2
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

<<<<<<< HEAD
            // ── Community Reports Badge ───────────────────
=======
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

>>>>>>> dev-ui2
            if (result.communityReports > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
<<<<<<< HEAD
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
=======
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
>>>>>>> dev-ui2
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
<<<<<<< HEAD
                        Text('Community Insights', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 14)),
=======
                        Text('Community Insights', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
>>>>>>> dev-ui2
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
<<<<<<< HEAD
                        Text('Reports Found', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
=======
                        Text('Reports Found', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
>>>>>>> dev-ui2
                        Text('${result.communityReports}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
<<<<<<< HEAD
                        Text('Verified by Others', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
=======
                        Text('Verified by Others', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
=======
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
=======
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
>>>>>>> dev-ui2
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.policy_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
<<<<<<< HEAD
                        Text('Verification Sources', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 14)),
=======
                        Text('Verification Sources', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                              color: Colors.blueAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
=======
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
=======
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
>>>>>>> dev-ui2
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< HEAD
                    Text('Analysis Details', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 14)),
=======
                    Text('Analysis Details', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 14)),
>>>>>>> dev-ui2
                    const SizedBox(height: 14),
                    ...result.reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chevron_right_rounded, color: riskColor, size: 18),
                          const SizedBox(width: 8),
<<<<<<< HEAD
                          Expanded(child: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4))),
=======
                          Expanded(child: Text(r, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4))),
>>>>>>> dev-ui2
                        ],
                      ),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── Quick Actions ───────────────────────────────
<<<<<<< HEAD
            if (isHigh) ...[
=======
            if (isHigh || isCritical) ...[
>>>>>>> dev-ui2
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
                      const SnackBar(content: Text('Calling PDRM (Mock)')),
=======
                      const SnackBar(content: Text('Calling NSRC (997) - Direct Emergency Line')),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  backgroundColor: isHigh ? const Color(0xFF1E293B) : AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isHigh ? 'Go Back' : 'Check Another', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
=======
                  backgroundColor: (isHigh || isCritical) ? const Color(0xFF1E293B) : AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text((isHigh || isCritical) ? 'Go Back' : 'Check Another', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
>>>>>>> dev-ui2
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
=======
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

>>>>>>> dev-ui2
  Widget _buildSourcePill(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
=======
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
>>>>>>> dev-ui2
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
<<<<<<< HEAD
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
=======
          Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
>>>>>>> dev-ui2
        ],
      ),
    );
  }
}
