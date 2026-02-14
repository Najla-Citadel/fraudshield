// lib/screens/qr_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/scan_history_service.dart';

class QRDetectionScreen extends StatefulWidget {
  const QRDetectionScreen({super.key});

  @override
  State<QRDetectionScreen> createState() => _QRDetectionScreenState();
}

class _QRDetectionScreenState extends State<QRDetectionScreen> {
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
        ),
      ),
    );
  }

  // 📷 STEP 1: Handle scan result
  void _foundBarcode(BarcodeCapture capture) {
    if (_isProcessing) return; // 🛑 Ignore if already processing/showing result
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty || raw == _lastScanned) return;

    setState(() {
      _isProcessing = true; // 🔒 Lock
      _lastScanned = raw;
    });

    // Use consolidated RiskEvaluator
    final result = RiskEvaluator.evaluate(type: 'QR', value: raw);

    // Save to history
    ScanHistoryService.addToHistory(ScanHistoryItem(
      content: raw,
      riskLevel: result.level,
      timestamp: DateTime.now(),
    ));

    _showResult(raw, result);
  }

  // 🧾 STEP 2: Show result UI
  void _showResult(String raw, RiskResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For glass effect
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _riskHeader(result),
            const SizedBox(height: 16),
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
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      text: 'Open Link',
                    ),
                  ),

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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).whenComplete(() {
      // Unlock scanning when closed
      setState(() {
        _isProcessing = false; 
        // Note: We keep _lastScanned set so we don't immediately re-scan the exact same code
        // unless the user moves the camera away and back.
        // If you WANT to allow immediate re-scan of the same code, clear _lastScanned here.
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
        break;
      default:
        color = Colors.grey;
        label = 'Unknown Risk';
        icon = Icons.help_outline;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🖼️ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera Layer (Full Screen)
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _foundBarcode,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('QR Detection', style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 5)])),
              leading: const BackButton(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: _showHistory,
                ),
                IconButton(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ),
          ),
          
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
          ),
        ],
      ),
    );
  }

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
}
