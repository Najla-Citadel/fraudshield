import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../services/scam_scanner_service.dart';
import '../services/api_service.dart';
import '../design_system/tokens/typography.dart';

class ScamScannerScreen extends StatefulWidget {
  final ScamScannerResult? initialResult;
  const ScamScannerScreen({super.key, this.initialResult});

  @override
  State<ScamScannerScreen> createState() => _ScamScannerScreenState();
}

class _ScamScannerScreenState extends State<ScamScannerScreen> {
  bool _isScanning = false;
  bool _isComplete = false;
  ScamScannerResult? _result;
  String _currentStep = 'Ready to scan';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _isComplete = true;
      _result = widget.initialResult;
    }
  }
  
  final List<String> _steps = [
    'Initializing scanner engine...',
    'Checking installed applications...',
    'Analyzing permission vulnerabilities...',
    'Scanning for hidden APK files...',
    'Cross-referencing with threat intelligence...',
    'Finalizing security report...'
  ];

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _isComplete = false;
      _progress = 0.0;
      _currentStep = _steps[0];
    });

    // Simulated progress for UI feedback while native scan runs
    int stepIndex = 0;
    Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (stepIndex < _steps.length - 1) {
        stepIndex++;
        if (mounted) {
          setState(() {
            _currentStep = _steps[stepIndex];
            _progress = (stepIndex + 1) / _steps.length;
          });
        }
      } else {
        timer.cancel();
      }
    });

    try {
      final result = await ScamScannerService.startFullScan();
      
      // Artificial delay to ensure user sees the "Finalizing" step
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isScanning = false;
          _isComplete = true;
          _result = result;
          _progress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _currentStep = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'DEVICE SECURITY SCAN',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          children: [
            if (!_isScanning && !_isComplete) _buildInitialState(),
            if (_isScanning) _buildScanningState(),
            if (_isComplete) _buildResultsState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SecurityTipsCard(tips: [
          'Regular device audits help detect hidden spyware and trackers.',
          'Reviewing high-risk permissions protects your private SMS/OTP data.',
          'FraudShield scans all installed apps for signatures of known scams.',
        ]),
        const SizedBox(height: 32),
        _buildEntryCard(
          title: 'Start Device Audit',
          subtitle: 'Full scan for malicious apps and risky permissions.',
          icon: LucideIcons.shieldCheck,
          color: DesignTokens.colors.accentGreen,
          onTap: _startScan,
        ),
        const SizedBox(height: 16),
        _buildEntryCard(
          title: 'Security Audit Logs',
          subtitle: 'Review previously detected threats and actions.',
          icon: LucideIcons.history,
          color: DesignTokens.colors.primary,
          onTap: () => Navigator.pushNamed(context, '/security-logs'),
        ),
      ],
    );
  }

  Widget _buildEntryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassSurface(
      borderRadius: 24,
      onTap: onTap,
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTypography.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Column(
      children: [
        SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.colors.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
                Text(
                  'SCANNING',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 48),
        GlassSurface(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          child: Row(
            children: [
              AppLoadingIndicator.center(size: 20),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  _currentStep,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsState() {
    final result = _result!;
    final riskyCount = result.riskyApps.length;
    final isSafe = riskyCount == 0;
    
    // Calculate a summary score based on results
    int baseScore = 100;
    for (var app in result.riskyApps) {
      baseScore -= app.score;
    }
    final finalScore = baseScore.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreHero(finalScore),
        SizedBox(height: 32),
        Text(
          'Detailed Findings',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        if (isSafe)
          _buildSafeCard()
        else
          ...result.riskyApps.map((app) => _buildRiskyAppCard(app)).toList(),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'BACK TO DASHBOARD',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHero(int score) {
    Color scoreColor = score >= 90 ? DesignTokens.colors.success : (score >= 70 ? DesignTokens.colors.warning : DesignTokens.colors.error);
    
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor.withOpacity(0.5), width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: TextStyle(color: scoreColor, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score >= 90 ? 'SECURE' : (score >= 70 ? 'ATTENTION' : 'CRITICAL'),
                      style: TextStyle(color: scoreColor, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Security health score based on system analysis',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeCard() {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      borderColor: DesignTokens.colors.success.withOpacity(0.3),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle2, color: DesignTokens.colors.success, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No threats detected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Your applications and permissions look safe.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskyAppCard(RiskyApp app) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        borderColor: DesignTokens.colors.error.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: DesignTokens.colors.error, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(app.packageName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${(app.score - app.scoreAdjustment).clamp(0, 100)}', 
                    style: TextStyle(color: DesignTokens.colors.error, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            if (app.scoreAdjustment != 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (app.scoreAdjustment > 0 ? DesignTokens.colors.success : DesignTokens.colors.error).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (app.scoreAdjustment > 0 ? DesignTokens.colors.success : DesignTokens.colors.error).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      app.scoreAdjustment > 0 ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                      color: app.scoreAdjustment > 0 ? DesignTokens.colors.success : DesignTokens.colors.error,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      app.scoreAdjustment > 0 ? 'Community Verdict: Likely Safe' : 'Community Verdict: Reported Threat',
                      style: TextStyle(
                        color: app.scoreAdjustment > 0 ? DesignTokens.colors.success : DesignTokens.colors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12),
            ...app.reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.dot, color: DesignTokens.colors.error, size: 16),
                  Expanded(child: Text(reason, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13))),
                ],
              ),
            )).toList(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'RESOLVE',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _showResolveOptions(app),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveOptions(RiskyApp app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.colors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resolve Threat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(app.name, style: TextStyle(color: Colors.white.withOpacity(0.5))),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: DesignTokens.colors.error),
              title: Text('Uninstall Application', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScamScannerService.uninstallApp(app.packageName);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.settings, color: Colors.white),
              title: Text('App Settings', style: TextStyle(color: Colors.white)),
              subtitle: Text('Force stop or check permissions', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScamScannerService.openAppSettings(app.packageName);
              },
            ),
            const Divider(color: Colors.white10, height: 32),
            Text('Community Intelligence', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.thumbsUp, color: DesignTokens.colors.success),
              title: Text('Flag as Safe', style: TextStyle(color: Colors.white)),
              subtitle: Text('I trust this application', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ApiService.instance.recordAppAction(app.packageName, 'SAFE');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you! Your feedback helps the community.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action already recorded or failed.')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.flag, color: DesignTokens.colors.error),
              title: Text('Report as Threat', style: TextStyle(color: Colors.white)),
              subtitle: Text('This application is suspicious', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ApiService.instance.recordAppAction(app.packageName, 'REPORT');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Threat reported to global database.')),
                    );
                  }
                } catch (e) {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action already recorded or failed.')),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
