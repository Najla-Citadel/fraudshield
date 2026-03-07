import 'package:flutter/material.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_snackbar.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import 'fraud_check_screen.dart';

class MessageAnalysisScreen extends StatefulWidget {
  const MessageAnalysisScreen({super.key});

  @override
  State<MessageAnalysisScreen> createState() => _MessageAnalysisScreenState();
}

class _MessageAnalysisScreenState extends State<MessageAnalysisScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  RiskResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please paste a message to analyze');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await RiskEvaluator.analyzeMessage(text);
      if (!mounted) return;
      setState(() => _isLoading = false);

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Analysis failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'AI MESSAGE SCANNER',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
            const SizedBox(height: 32),
            const Text(
              'Paste Message Content',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              borderRadius: 24,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _controller,
                maxLines: 8,
                minLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'Paste a suspicious SMS, WhatsApp message, or email here...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const AppLoadingIndicator(
                        color: Colors.white,
                        size: 20,
                      )
                    : const Text(
                        'Analyze Message',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            _featureRow(
              'Language Agnostic',
              'Analyzes English, Bahasa Malaysia, and Mandarin.',
              LucideIcons.languages,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _featureRow(
              'Hook Detection',
              'Identifies urgency, financial triggers, and impersonation.',
              LucideIcons.radar,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();
    final isRisky = _result!.score >= 50;
    final color = isRisky ? Colors.red : Colors.green;

    return GlassSurface(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      borderColor: color.withOpacity(0.3),
      child: Column(
        children: [
          Icon(
            isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isRisky ? 'Threat Detected' : 'Message Looks Safe',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Risk Score: ${_result!.score}/100',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (_result!.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            ..._result!.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          color: color.withOpacity(0.5), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.colors.primary,
            DesignTokens.colors.primary.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.shieldCheck, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Chat Defense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Instantly detect phishing, impersonation, and scam hooks.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String title, String desc, IconData icon, Color color) {
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
