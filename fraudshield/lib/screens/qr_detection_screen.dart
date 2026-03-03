// lib/screens/qr_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
<<<<<<< HEAD
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_scaffold.dart';
=======
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
>>>>>>> dev-ui2
import '../widgets/adaptive_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/scan_history_service.dart';

<<<<<<< HEAD
=======
////////////////////////////////////////////////////////////////
/// 1. DASHBOARD SCREEN (Entry Point)
////////////////////////////////////////////////////////////////

>>>>>>> dev-ui2
class QRDetectionScreen extends StatefulWidget {
  const QRDetectionScreen({super.key});

  @override
  State<QRDetectionScreen> createState() => _QRDetectionScreenState();
}

class _QRDetectionScreenState extends State<QRDetectionScreen> {
<<<<<<< HEAD
  // MobileScannerController handles its own lifecycle by default or when passed to the widget.
  // We enable autoStart (default is true) and torch disabled.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    autoStart: true, 
  );
  String? _lastScanned;
  bool _isTorchOn = false;
  bool _isProcessing = false;

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Scan History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ScanHistoryItem>>(
                  future: ScanHistoryService.getHistory(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(child: Text('No scan history yet'));
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return ListTile(
                          leading: Icon(
                            item.riskLevel == 'low' 
                                ? Icons.check_circle 
                                : Icons.warning,
                            color: item.riskLevel == 'low' 
                                ? Colors.green 
                                : Colors.red,
                          ),
                          title: Text(
                            item.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.timestamp.toLocal().toString().split('.')[0],
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                             Navigator.pop(context); // Close history
                             // Manually trigger process for this item
                             final result = RiskEvaluator.evaluate(type: 'QR', value: item.content);
                             _showResult(item.content, result);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
=======
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
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  AppColors.deepNavy,
                  Color(0xFF1E3A8A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroScanButton(),
                        const SizedBox(height: 40),
                        const Text(
                          'Recent Scans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                  color: AppColors.accentGreen),
                            ),
                          )
                        else if (_history.isEmpty)
                          _buildEmptyState()
                        else
                          _buildHistoryList(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'QR Security Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.white38),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.deepNavy,
                  title: const Text('Clear History?',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('This will remove all recent scans.',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear',
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
      ),
    );
  }

  Widget _buildHeroScanButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QRScannerCameraScreen()),
        );
        _loadHistory();
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.scanLine,
                  color: AppColors.accentGreen, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan New QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Instantly check URLs for phishing and threats',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
>>>>>>> dev-ui2
        ),
      ),
    );
  }

<<<<<<< HEAD
  // 📷 STEP 1: Handle scan result
  void _foundBarcode(BarcodeCapture capture) {
    if (_isProcessing) return; // 🛑 Ignore if already processing/showing result
=======
  Widget _buildHistoryList() {
    return Column(
      children: _history.map((item) {
        final isSafe = item.riskLevel == 'low';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? LucideIcons.check : LucideIcons.alertTriangle,
                color: isSafe ? AppColors.accentGreen : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              item.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${_formatTimestamp(item.timestamp)} • ${item.riskLevel.toUpperCase()}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(LucideIcons.chevronRight,
                color: Colors.white24, size: 16),
            onTap: () {
              // Show report details (Re-using evaluation from Camera screen if needed)
              final result =
                  RiskEvaluator.evaluate(type: 'QR', value: item.content);
              _showStaticResult(item.content, result);
            },
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
          const SizedBox(height: 40),
          Icon(LucideIcons.history,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No scan history yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _riskHeader(result),
            const SizedBox(height: 16),
            const Text('Content:',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(raw,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontFamily: 'Courier')),
            const SizedBox(height: 24),
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
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'Close',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
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
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text('Risk Score: ${result.score}/100',
                style: TextStyle(
                    fontSize: 12, color: color.withValues(alpha: 0.7))),
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
>>>>>>> dev-ui2
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty || raw == _lastScanned) return;

    setState(() {
<<<<<<< HEAD
      _isProcessing = true; // 🔒 Lock
      _lastScanned = raw;
    });

    // Use consolidated RiskEvaluator
    final result = RiskEvaluator.evaluate(type: 'QR', value: raw);

    // Save to history
=======
      _isProcessing = true;
      _lastScanned = raw;
    });

    _showLoading(raw);

    final result = await RiskEvaluator.evaluateQr(raw);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

>>>>>>> dev-ui2
    ScanHistoryService.addToHistory(ScanHistoryItem(
      content: raw,
      riskLevel: result.level,
      timestamp: DateTime.now(),
    ));

    _showResult(raw, result);
  }

<<<<<<< HEAD
  // 🧾 STEP 2: Show result UI
  void _showResult(String raw, RiskResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For glass effect
=======
  void _showLoading(String raw) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.accentGreen),
              const SizedBox(height: 24),
              const Text('Analyzing QR Content...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
>>>>>>> dev-ui2
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
<<<<<<< HEAD
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
=======
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
>>>>>>> dev-ui2
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _riskHeader(result),
            const SizedBox(height: 16),
<<<<<<< HEAD
            Text(
              'Content:',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raw,
              style: const TextStyle(fontSize: 14, fontFamily: 'Courier'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis:',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // List reasons with icons
            ...result.reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, size: 16, color: AppColors.greyText),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(color: AppColors.darkText),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 30),

            // 🔘 Action buttons
            Row(
              children: [
                if (result.level != 'high')
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(raw);
=======
            const Text('Content:',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(raw,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontFamily: 'Courier'),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            const Text('Analysis:',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...result.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldCheck,
                          size: 14,
                          color:
                              r.startsWith('✅') ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13))),
                    ],
                  ),
                )),
            const SizedBox(height: 30),
            Row(
              children: [
                if (result.level != 'high' && result.level != 'critical')
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(result.finalUrl ?? raw);
>>>>>>> dev-ui2
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      text: 'Open Link',
                    ),
                  ),
<<<<<<< HEAD

                if (result.level == 'high')
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'Close (Unsafe)',
                      // backgroundColor: Colors.red, // Assuming AdaptiveButton supports color
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.thumb_up, size: 16),
                    label: const Text('Report Safe'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reported as Safe ✅')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.thumb_down, size: 16),
                    label: const Text('Report Unsafe'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reported as Unsafe 🚨')),
                      );
                      Navigator.pop(context);
                    },
=======
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => Navigator.pop(context),
                    text: result.level == 'low' ? 'Done' : 'Close',
>>>>>>> dev-ui2
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).whenComplete(() {
<<<<<<< HEAD
      // Unlock scanning when closed
      setState(() {
        _isProcessing = false; 
        // Note: We keep _lastScanned set so we don't immediately re-scan the exact same code
        // unless the user moves the camera away and back.
        // If you WANT to allow immediate re-scan of the same code, clear _lastScanned here.
         _lastScanned = null; 
=======
      setState(() {
        _isProcessing = false;
        _lastScanned = null;
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        icon = Icons.check_circle;
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Suspicious QR Code';
        icon = Icons.warning_amber;
        break;
      case 'high':
        color = Colors.red;
        label = 'High Risk QR Code';
        icon = Icons.dangerous;
=======
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
>>>>>>> dev-ui2
        break;
      default:
        color = Colors.grey;
        label = 'Unknown Risk';
<<<<<<< HEAD
        icon = Icons.help_outline;
=======
        icon = LucideIcons.helpCircle;
>>>>>>> dev-ui2
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (result.score > 0)
            Text(
              'Risk Score: ${result.score}/100',
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
=======
            Text(label,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text('Risk Score: ${result.score}/100',
                style: TextStyle(
                    fontSize: 12, color: color.withValues(alpha: 0.7))),
>>>>>>> dev-ui2
          ],
        ),
      ],
    );
  }

  @override
<<<<<<< HEAD
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🖼️ UI
  @override
=======
>>>>>>> dev-ui2
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
<<<<<<< HEAD
          // 1. Camera Layer (Full Screen)
=======
>>>>>>> dev-ui2
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _foundBarcode,
<<<<<<< HEAD
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enable camera permissions in settings.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. App Bar Layer (Transparent)
=======
          ),
>>>>>>> dev-ui2
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
<<<<<<< HEAD
              title: const Text('QR Detection', style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 5)])),
              leading: const BackButton(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: _showHistory,
                ),
                IconButton(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
=======
              title:
                  const Text('Scan QR', style: TextStyle(color: Colors.white)),
              leading: const BackButton(color: Colors.white),
              actions: [
                IconButton(
                  icon: Icon(_isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      color: Colors.white),
>>>>>>> dev-ui2
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
<<<<<<< HEAD
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
=======
                  icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
>>>>>>> dev-ui2
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ),
          ),
<<<<<<< HEAD
          
          // 3. Scan Overlay Guide
          Center(
             child: Container(
               width: 250,
               height: 250,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.white70, width: 2),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: const [
                   Padding(
                     padding: EdgeInsets.all(8.0),
                     child: Text(
                       'Align QR code within frame',
                       style: TextStyle(color: Colors.white70, fontSize: 12),
                       textAlign: TextAlign.center,
                     ),
                   ),
                 ],
               ),
             ),
=======
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Center QR code in frame',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
>>>>>>> dev-ui2
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD

  Widget _debugButton(String label, String value) {
    return GestureDetector(
      onTap: () {
         final result = RiskEvaluator.evaluate(type: 'QR', value: value);
         _showResult(value, result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text(label, style: const TextStyle(color: Colors.black)),
      ),
    );
  }
=======
>>>>>>> dev-ui2
}
