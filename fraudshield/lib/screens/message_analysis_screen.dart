import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../services/api_service.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../widgets/adaptive_button.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageAnalysisScreen extends StatefulWidget {
  const MessageAnalysisScreen({super.key});

  @override
  State<MessageAnalysisScreen> createState() => _MessageAnalysisScreenState();
}

class _MessageAnalysisScreenState extends State<MessageAnalysisScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _recentChecks = [];
  bool _isFetchingHistory = true;
  DateTime? _lastClearedAt;

  @override
  void initState() {
    super.initState();
    _loadClearedTimestamp().then((_) => _fetchHistory());
  }

  Future<void> _loadClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('msg_history_cleared_at');
    if (ts != null) {
      if (mounted) setState(() => _lastClearedAt = DateTime.parse(ts));
    }
  }

  Future<void> _saveClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('msg_history_cleared_at', now.toIso8601String());
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
            if (type != 'MSG') return false;

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
      debugPrint('Error fetching message history: $e');
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

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

      _showResultSheet(text, result);
      _fetchHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Analysis failed: $e');
    }
  }

  void _showResultSheet(String text, RiskResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: EdgeInsets.all(DesignTokens.spacing.lg),
        child: GlassSurface(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              SizedBox(height: 24),
              _buildRiskHeader(result),
              SizedBox(height: 24),
              
              // Score Meter
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: result.score / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(_getRiskColor(result.score)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${result.score}',
                          style: DesignTypography.h1.copyWith(fontSize: 32),
                        ),
                        Text(
                          '/ 100',
                          style: DesignTypography.caption.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              Text('MESSAGE CONTENT',
                  style: DesignTypography.bodyXs.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                constraints: BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      )),
                ),
              ),
              SizedBox(height: 20),
              
              Text('ANALYSIS BREAKDOWN',
                  style: DesignTypography.bodyXs.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
              SizedBox(height: 12),
              if (result.reasons.isEmpty)
                Text('Scan yielded no immediate threats.', style: TextStyle(color: Colors.white54, fontSize: 13))
              else
                ...result.reasons.map((r) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          result.score < 55
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertTriangle,
                          size: 16,
                          color: result.score < 55
                              ? DesignTokens.colors.accentGreen
                              : Colors.amber,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(r,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                  height: 1.4,
                                ))),
                      ],
                    ),
                  )),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () => Navigator.pop(context),
                      text: result.score < 55 ? 'Done' : 'Understood',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskHeader(RiskResult result) {
    Color color = _getRiskColor(result.score);
    String label;
    IconData icon;

    if (result.score >= 70) {
      label = 'Severe Threat';
      icon = LucideIcons.shieldAlert;
    } else if (result.score >= 40) {
      label = 'Suspicious Hook';
      icon = LucideIcons.alertTriangle;
    } else {
      label = 'Safe Message';
      icon = LucideIcons.shieldCheck;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: DesignTypography.h3.copyWith(color: color)),
            Text('Probability Score: ${result.score}%',
                style: DesignTypography.caption.copyWith(color: color.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return DesignTokens.colors.error;
    if (score >= 40) return Colors.amber;
    return DesignTokens.colors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Message Security Hub',
      actions: [
        IconButton(
          icon: Icon(LucideIcons.trash2, color: Colors.white38),
          onPressed: () async {
            if (_recentChecks.isEmpty) return;
            
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: DesignTokens.colors.backgroundDark,
                title: Text('Clear History?',
                    style: TextStyle(color: Colors.white)),
                content: Text('This will remove all message analysis history.',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Clear',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            
            if (confirm == true) {
              _saveClearedTimestamp();
              setState(() => _recentChecks = []);
            }
          },
        ),
      ],
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
                  'Scammers use urgent language to trigger immediate action.',
                  'Never share OTPs or login credentials via chat links.',
                  'Official entities rarely contact you via WhatsApp or Telegram.',
                ]),
                const SizedBox(height: 28),
                
                // Smart Analyzer Card
                GlassSurface(
                  borderRadius: 24,
                  padding: EdgeInsets.all(DesignTokens.spacing.xl),
                  accentColor: DesignTokens.colors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: DesignTokens.colors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(LucideIcons.messageSquare,
                                    color: DesignTokens.colors.primary, size: 20),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Analyzer',
                                    style: DesignTypography.labelLg,
                                  ),
                                  Text(
                                    'Multi-language protection',
                                    style: DesignTypography.caption
                                        .copyWith(color: Colors.white38),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        maxLines: 6,
                        minLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Paste message here...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.2)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: DesignTokens.colors.primary.withOpacity(0.3)),
                          ),
                          contentPadding: EdgeInsets.all(DesignTokens.spacing.lg),
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      AdaptiveButton(
                        text: 'Analyze Message',
                        isLoading: _isLoading,
                        onPressed: _analyze,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Recent Activity',
                  style: DesignTypography.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildRecentActivity(),
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
        final value = scan['target']?.toString() ?? 'Message Scan';
        final dateStr = scan['createdAt']?.toString();
        if (dateStr == null) return SizedBox.shrink();
        final date = DateTime.parse(dateStr);
        final formattedDate = _formatTimestamp(date);
        
        final status = scan['status']?.toString().toUpperCase() ?? 'SAFE';
        final isSafe = status == 'SAFE';
        final accentColor = isSafe ? DesignTokens.colors.success : DesignTokens.colors.error;

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacing.md),
          child: GlassSurface(
            onTap: () {
              setState(() => _controller.text = value);
              _analyze();
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
                        '$formattedDate • $status',
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
