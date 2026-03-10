import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../services/api_service.dart';
import '../design_system/components/app_snackbar.dart';
import '../widgets/adaptive_button.dart';

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

    _showResultSheet(_inputController.text.trim(), result);
    _fetchHistory();
  }

  void _showResultSheet(String value, RiskResult result) {
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
                        valueColor: AlwaysStoppedAnimation<Color>(_getRiskColor(result.level)),
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
              
              Text('ANALYZED INPUT',
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
                child: Text(value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              SizedBox(height: 20),
              
              Text('ANALYSIS BREAKDOWN',
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
                        Icon(
                          r.contains('Safe') || r.contains('Verified')
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertTriangle,
                          size: 16,
                          color: r.contains('Safe') || r.contains('Verified')
                              ? DesignTokens.colors.accentGreen
                              : Colors.amber,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(r.replaceAll(RegExp(r'^[✅⚠️🤖]\s*'), ''),
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
    Color color = _getRiskColor(result.level);
    String label;
    IconData icon;

    switch (result.level) {
      case 'low':
        label = 'Secure Target';
        icon = LucideIcons.shieldCheck;
        break;
      case 'medium':
        label = 'Suspicious Activity';
        icon = LucideIcons.alertTriangle;
        break;
      case 'high':
      case 'critical':
        label = 'Threat Detected';
        icon = LucideIcons.shieldAlert;
        break;
      default:
        label = 'Analysis Results';
        icon = LucideIcons.helpCircle;
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
            Text('Risk Level: ${result.level.toUpperCase()}',
                style: DesignTypography.caption.copyWith(color: color.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low': return DesignTokens.colors.accentGreen;
      case 'medium': return Colors.amber;
      case 'high': 
      case 'critical': return DesignTokens.colors.error;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    
    return ScreenScaffold(
      title: 'Payment Security Hub',
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
                content: Text('This will remove all recent payment check activity.',
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
                  'Always verify the identity of the recipient before transferring money.',
                  'Scammers often create a sense of urgency to pressure you.',
                  'Fraudulent accounts are often recently created or "mule" accounts.',
                ]),
                const SizedBox(height: 28),
                
                // Smart Analyzer card
                GlassSurface(
                  borderRadius: 24,
                  padding: EdgeInsets.all(DesignTokens.spacing.xl),
                  accentColor: colors.primary,
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
                                  color: colors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(LucideIcons.search,
                                    color: colors.primary, size: 20),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Analyzer',
                                    style: DesignTypography.labelLg,
                                  ),
                                  Text(
                                    'Phone or Bank Account',
                                    style: DesignTypography.caption
                                        .copyWith(color: Colors.white38),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_detectedType == 'Payment' &&
                              _inputController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radii.xs),
                                border: Border.all(
                                    color: colors.primary.withOpacity(0.2)),
                              ),
                              child: Text(
                                'DETECTED',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _inputController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Enter number to analyze...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.2)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          prefixIcon: Icon(_detectedIcon,
                              color: colors.primary.withOpacity(0.5), size: 18),
                          suffixIcon: _inputController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(LucideIcons.xCircle,
                                      color: Colors.white.withOpacity(0.2),
                                      size: 18),
                                  onPressed: () {
                                    _inputController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: colors.primary.withOpacity(0.3)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacing.lg,
                              vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Courier',
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 24),
                      AdaptiveButton(
                        text: 'Analyze Content',
                        isLoading: _isLoading,
                        onPressed: _check,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: DesignTypography.h3.copyWith(color: colors.textLight),
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
