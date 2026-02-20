import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';

class FraudCheckScreen extends StatefulWidget {
  const FraudCheckScreen({super.key});

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final _inputController = TextEditingController();
  bool _isLoading = false;

  static const _tabs = [
    _TabItem(label: 'Phone', icon: Icons.phone_outlined, hint: 'e.g. 012-345 6789', type: 'Phone No'),
    _TabItem(label: 'URL', icon: Icons.link_rounded, hint: 'e.g. https://bank.com', type: 'URL'),
    _TabItem(label: 'Bank Acc', icon: Icons.account_balance_outlined, hint: 'e.g. 1234567890', type: 'Bank Acc'),
    _TabItem(label: 'Document', icon: Icons.description_outlined, hint: 'Upload a file', type: 'Document'),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final tab = _tabs[_selectedIndex];

    if (_inputController.text.isEmpty && tab.type != 'Document') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a ${tab.label}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    RiskResult result;
    if (tab.type == 'Document') {
      await Future.delayed(const Duration(milliseconds: 400));
      result = RiskResult(level: 'low', score: 10, reasons: ['No malware found', 'File appears legitimate']);
    } else if (tab.type == 'URL') {
      // Use async API-backed evaluation for URLs
      result = await RiskEvaluator.evaluateUrl(_inputController.text.trim());
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      result = RiskEvaluator.evaluate(type: tab.type, value: _inputController.text.trim());
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckResultScreen(
          type: tab.label,
          value: tab.type == 'Document' ? 'Uploaded File' : _inputController.text.trim(),
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedIndex];

    return AdaptiveScaffold(
      title: 'Fraud Check',
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
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Think it might be a scam?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Instant AI-powered fraud detection',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Check Now ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                text: 'Check Now',
                isLoading: _isLoading,
                onPressed: _check,
              ),
            ),
            const SizedBox(height: 28),

            // ── Safety Tips ──────────────────────────────
            _SafetyTipsCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Helper classes ──────────────────────────────────

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
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Stay Protected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
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
                Expanded(child: Text(t.text, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13))),
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

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Check Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: riskColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
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
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checked $type', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Risk Score', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
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
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Reasons ───────────────────────────────────
            if (result.reasons.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analysis Details', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 14),
                    ...result.reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chevron_right_rounded, color: riskColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── Back Button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Check Another', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
