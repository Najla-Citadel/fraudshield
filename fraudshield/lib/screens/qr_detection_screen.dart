import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/tokens/design_tokens.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/scan_history_service.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import '../design_system/tokens/typography.dart';

////////////////////////////////////////////////////////////////
/// 1. DASHBOARD SCREEN (Entry Point)
////////////////////////////////////////////////////////////////

class QRDetectionScreen extends StatefulWidget {
  const QRDetectionScreen({super.key});

  @override
  State<QRDetectionScreen> createState() => _QRDetectionScreenState();
}

class _QRDetectionScreenState extends State<QRDetectionScreen> {
  List<ScanHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await ScanHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = h;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'QR Security Hub',
      actions: [
        IconButton(
          icon: Icon(LucideIcons.trash2, color: Colors.white38),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: DesignTokens.colors.backgroundDark,
                title: Text('Clear History?',
                    style: TextStyle(color: Colors.white)),
                content: Text('This will remove all recent scans.',
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
              await ScanHistoryService.clearHistory();
              _loadHistory();
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
              'Always verify the URL matches the expected domain.',
              'Be cautious of QR codes in unexpected places.',
              'Report suspicious codes to help protect others.',
            ]),
            SizedBox(height: 32),
            _buildScanActionCard(),
            SizedBox(height: 32),
            Text(
              'Recent Scans',
              style: DesignTypography.h3,
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AppLoadingIndicator(
                      size: 40,
                      strokeWidth: 4,
                      color: DesignTokens.colors.accentGreen),
                ),
              )
            else if (_history.isEmpty)
              _buildEmptyState()
            else
              _buildHistoryList(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScanActionCard() {
    return GlassSurface(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QRScannerCameraScreen()),
        );
        _loadHistory();
      },
      borderRadius: 24,
      accentColor: DesignTokens.colors.accentGreen,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              color: DesignTokens.colors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            ),
            child: Icon(LucideIcons.scanLine,
                color: DesignTokens.colors.accentGreen, size: 32),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan New QR Code',
                  style: DesignTypography.h3,
                ),
                SizedBox(height: 4),
                Text(
                  'Instantly check URLs for threats',
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

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return DesignTokens.colors.accentGreen;
      case 'medium':
        return DesignTokens.colors.warning;
      case 'high':
      case 'critical':
        return DesignTokens.colors.error;
      default:
        return DesignTokens.colors.textGrey;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return LucideIcons.shieldCheck;
      case 'medium':
        return LucideIcons.alertTriangle;
      case 'high':
      case 'critical':
        return LucideIcons.shieldAlert;
      default:
        return LucideIcons.shield;
    }
  }

  Widget _buildHistoryList() {
    return Column(
      children: _history.map((item) {
        final level = item.riskLevel.toLowerCase();
        final accentColor = _getRiskColor(level);
        final riskIcon = _getRiskIcon(level);

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacing.md),
          child: GlassSurface(
            onTap: () {
              final result =
                  RiskEvaluator.evaluate(type: 'QR', value: item.content);
              _showStaticResult(item.content, result);
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
                    riskIcon,
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
                        item.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_formatTimestamp(item.timestamp)} • ${item.riskLevel.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
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
    return '${ts.day}/${ts.month}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(LucideIcons.history,
              size: 64, color: Colors.white.withOpacity(0.1)),
          SizedBox(height: 16),
          Text(
            'No scan history yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showStaticResult(String raw, RiskResult result) {
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
              _riskHeader(result),
              SizedBox(height: 20),
              Text('CONTENT',
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
                child: Text(raw,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontFamily: 'Courier',
                    )),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  if (result.level != 'high' && result.level != 'critical')
                    Expanded(
                      child: AdaptiveButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(result.finalUrl ?? raw);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        text: 'Open Link',
                      ),
                    ),
                  if (result.level != 'high' && result.level != 'critical')
                    SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'Close',
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

  Widget _riskHeader(RiskResult result) {
    Color color;
    String label;
    IconData icon;

    switch (result.level) {
      case 'low':
        color = Colors.green;
        label = 'Safe QR Code';
        icon = LucideIcons.checkCircle;
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Suspicious QR';
        icon = LucideIcons.alertCircle;
        break;
      case 'high':
      case 'critical':
        color = Colors.red;
        label = 'Threat Detected';
        icon = LucideIcons.shieldAlert;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown Risk';
        icon = LucideIcons.helpCircle;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text('Risk Score: ${result.score}/100',
                style: TextStyle(
                    fontSize: 12, color: color.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////
/// 2. CAMERA SCANNER SCREEN
////////////////////////////////////////////////////////////////

class QRScannerCameraScreen extends StatefulWidget {
  const QRScannerCameraScreen({super.key});

  @override
  State<QRScannerCameraScreen> createState() => _QRScannerCameraScreenState();
}

class _QRScannerCameraScreenState extends State<QRScannerCameraScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    autoStart: true,
  );
  String? _lastScanned;
  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _foundBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty || raw == _lastScanned) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = raw;
    });

    _showLoading(raw);

    final result = await RiskEvaluator.evaluateQr(raw);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    ScanHistoryService.addToHistory(ScanHistoryItem(
      content: raw,
      riskLevel: result.level,
      timestamp: DateTime.now(),
    ));

    _showResult(raw, result);
  }

  void _showLoading(String raw) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoadingIndicator(color: DesignTokens.colors.accentGreen),
              SizedBox(height: 24),
              Text('Analyzing QR Content...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxxl),
                child: Text(raw,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResult(String raw, RiskResult result) {
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
              _riskHeader(result),
              SizedBox(height: 20),
              Text('CONTENT',
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
                child: Text(raw,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontFamily: 'Courier',
                    )),
              ),
              SizedBox(height: 20),
              Text('ANALYSIS',
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
                  if (result.level != 'high' && result.level != 'critical')
                    Expanded(
                      child: AdaptiveButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(result.finalUrl ?? raw);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        text: 'Open Link',
                      ),
                    ),
                  if (result.level != 'high' && result.level != 'critical')
                    SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () => Navigator.pop(context),
                      text: result.level == 'low' ? 'Done' : 'Close',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _isProcessing = false;
        _lastScanned = null;
      });
    });
  }

  Widget _riskHeader(RiskResult result) {
    Color color;
    String label;
    IconData icon;

    switch (result.level) {
      case 'low':
        color = Colors.green;
        label = 'Safe QR Code';
        icon = LucideIcons.checkCircle;
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Suspicious QR';
        icon = LucideIcons.alertCircle;
        break;
      case 'high':
      case 'critical':
        color = Colors.red;
        label = 'Threat Detected';
        icon = LucideIcons.shieldAlert;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown Risk';
        icon = LucideIcons.helpCircle;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text('Risk Score: ${result.score}/100',
                style: TextStyle(
                    fontSize: 12, color: color.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _foundBarcode,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title:
                  Text('Scan QR', style: TextStyle(color: Colors.white)),
              leading: const BackButton(color: Colors.white),
              actions: [
                IconButton(
                  icon: Icon(_isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      color: Colors.white),
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
                  icon: Icon(LucideIcons.refreshCw, color: Colors.white),
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.spacing.sm),
                  child: Text('Center QR code in frame',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
