import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../services/api_service.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/adaptive_button.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/components/app_snackbar.dart';

class UrlLinkCheckScreen extends StatefulWidget {
  const UrlLinkCheckScreen({super.key});

  @override
  State<UrlLinkCheckScreen> createState() => _UrlLinkCheckScreenState();
}

class _UrlLinkCheckScreenState extends State<UrlLinkCheckScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _recentScans = [];
  bool _isFetchingHistory = true;
  DateTime? _lastClearedAt;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() => setState(() {}));
    _loadClearedTimestamp().then((_) => _fetchHistory());
  }

  Future<void> _loadClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('url_history_cleared_at');
    if (ts != null) {
      if (mounted) setState(() => _lastClearedAt = DateTime.parse(ts));
    }
  }

  Future<void> _saveClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('url_history_cleared_at', now.toIso8601String());
    if (mounted) setState(() => _lastClearedAt = now);
  }

  Future<void> _fetchHistory() async {
    try {
      final response =
          await ApiService.instance.getTransactionJournal(type: 'URL');
      if (mounted) {
        setState(() {
          List<dynamic> results = response['results'] ?? [];
          // Filter out scans before _lastClearedAt
          if (_lastClearedAt != null) {
            results = results.where((scan) {
              final scanDate = DateTime.parse(scan['createdAt']);
              return scanDate.isAfter(_lastClearedAt!);
            }).toList();
          }
          _recentScans = results;
          _isFetchingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching URL history: $e');
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await RiskEvaluator.evaluateUrl(url);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showResultSheet(url, result);
        
        // Refresh history after check
        _fetchHistory();
      }
    } catch (e) {
      debugPrint('Error checking URL: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Failed to check URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'URL Security Hub',
      actions: [
        IconButton(
          icon: Icon(LucideIcons.trash2, color: Colors.white38),
          onPressed: () async {
            if (_recentScans.isEmpty) return;
            
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: DesignTokens.colors.backgroundDark,
                title: Text('Clear History?',
                    style: TextStyle(color: Colors.white)),
                content: Text('This will remove all recent URL check activity.',
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
              setState(() => _recentScans = []);
            }
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SecurityTipsCard(tips: [
              'Check links from SMS, WhatsApp, or email before opening.',
              'Avoid clicking links that create a false sense of urgency.',
              "Always verify the domain name (e.g., 'google.com' vs 'qooqle.com').",
            ]),
            SizedBox(height: 32),
            _buildInputSection(),
            SizedBox(height: 32),
            Text(
              'Recent Activity',
              style: DesignTypography.h3,
            ),
            SizedBox(height: 16),
            _buildRecentActivity(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      borderRadius: 24,
      accentColor: DesignTokens.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.shield, color: DesignTokens.colors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Link Analyzer',
                    style: DesignTypography.labelLg,
                  ),
                  Text(
                    'Stay protected from malicious URLs',
                    style: DesignTypography.caption.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'Paste or type URL here...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              prefixIcon: Icon(LucideIcons.link,
                  color: DesignTokens.colors.primary.withOpacity(0.5), size: 18),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(LucideIcons.xCircle,
                          color: Colors.white.withOpacity(0.2), size: 18),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: DesignTokens.colors.primary.withOpacity(0.3)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: 16),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Courier'),
          ),
          SizedBox(height: 24),
          AdaptiveButton(
            onPressed: _isLoading ? null : _checkUrl,
            text: 'Analyze Link',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int score, String status) {
    if (score >= 75 || status == 'SCAMMED' || status == 'BLOCKED') return DesignTokens.colors.error;
    if (score >= 30 || status == 'SUSPICIOUS') return DesignTokens.colors.warning;
    return DesignTokens.colors.accentGreen;
  }

  IconData _getRiskIcon(int score, String status) {
    if (score >= 75 || status == 'SCAMMED' || status == 'BLOCKED') return LucideIcons.shieldAlert;
    if (score >= 30 || status == 'SUSPICIOUS') return LucideIcons.alertTriangle;
    return LucideIcons.shieldCheck;
  }

  String _getRiskLabel(int score, String status) {
    if (status == 'SCAMMED') return 'SCAMMED';
    if (status == 'BLOCKED') return 'BLOCKED';
    if (score >= 75) return 'RISKY';
    if (score >= 30) return 'SUSPICIOUS';
    return 'SAFE';
  }

  void _showResultSheet(String url, RiskResult result) {
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
              SizedBox(height: 20),
              Text('TARGET URL',
                  style: DesignTypography.bodyXs.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(url,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontFamily: 'Courier',
                    )),
              ),
              SizedBox(height: 20),
              Text('RISK ANALYSIS',
                  style: DesignTypography.bodyXs.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
              SizedBox(height: 12),
              ...result.reasons.map((r) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          child: Icon(
                            r.contains('Safe') || r.contains('valid')
                                ? LucideIcons.checkCircle
                                : LucideIcons.alertTriangle,
                            size: 16,
                            color: r.contains('Safe') || r.contains('valid')
                                ? DesignTokens.colors.accentGreen
                                : DesignTokens.colors.warning,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(r.replaceAll(RegExp(r'^[✅⚠️]\s*'), ''),
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
                      text: result.level == 'low' ? 'Done' : 'Understood',
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
    final Color color = _getRiskColor(result.score, '');
    final String label = result.level == 'low' ? 'Secure Link' : _getRiskLabel(result.score, '');
    final IconData icon = _getRiskIcon(result.score, '');

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
            Text('Risk Level: ${result.level.toUpperCase()}',
                style: DesignTypography.caption.copyWith(color: color.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    if (_isFetchingHistory) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: AppLoadingIndicator.center(),
      );
    }

    if (_recentScans.isEmpty) {
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
        children: _recentScans.map((scan) {
          final score = (scan['riskScore'] ?? 0) as int;
          final status = (scan['status'] ?? 'SAFE') as String;
          final accentColor = _getRiskColor(score, status);
          final label = _getRiskLabel(score, status);
          final icon = _getRiskIcon(score, status);
          
          final DateTime date = DateTime.parse(scan['createdAt']);
          final String formattedDate = _formatTimestamp(date);

          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacing.md),
            child: GlassSurface(
              onTap: () {
                final url = scan['target'] ?? 'Unknown URL';
                setState(() => _urlController.text = url);
                _checkUrl();
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
                      icon,
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
                          scan['target'] ?? 'Unknown URL',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTypography.labelMd,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$formattedDate • $label',
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
