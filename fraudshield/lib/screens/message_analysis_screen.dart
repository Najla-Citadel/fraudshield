import 'package:flutter/material.dart';
import '../design_system/components/app_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_snackbar.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';

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
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            if (_result != null) ...[
              SizedBox(height: 24),
              _buildResultCard(),
            ],
            SizedBox(height: 32),
            Text(
              'Paste Message Content',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
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
                  contentPadding: EdgeInsets.all(DesignTokens.spacing.xl),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            AppButton(
              onPressed: _isLoading ? null : _analyze,
              label: 'Analyze Message',
              variant: AppButtonVariant.primary,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            SizedBox(height: 40),
            _featureRow(
              'Language Agnostic',
              'Analyzes English, Bahasa Malaysia, and Mandarin.',
              LucideIcons.languages,
              Colors.orange,
            ),
            SizedBox(height: 16),
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
    if (_result == null) return SizedBox.shrink();
    final isRisky = _result!.score >= 50;
    final color = isRisky ? Colors.red : Colors.green;

    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      borderRadius: 24,
      borderColor: color.withOpacity(0.3),
      child: Column(
        children: [
          Icon(
            isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
            color: color,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            isRisky ? 'Threat Detected' : 'Message Looks Safe',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Risk Score: ${_result!.score}/100',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (_result!.reasons.isNotEmpty) ...[
            SizedBox(height: 16),
            Divider(color: Colors.white10),
            SizedBox(height: 16),
            ..._result!.reasons.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          color: color.withOpacity(0.5), size: 14),
                      SizedBox(width: 8),
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
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.colors.primary,
            DesignTokens.colors.primary.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            ),
            child: Icon(LucideIcons.shieldCheck, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
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
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
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
                SizedBox(height: 4),
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
