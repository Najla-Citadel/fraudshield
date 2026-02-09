// lib/screens/qr_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

enum QRRiskLevel { safe, suspicious, high, unknown }

class QRScanResult {
  final QRRiskLevel risk;
  final String reason;

  QRScanResult({
    required this.risk,
    required this.reason,
  });
}

class QRDetectionScreen extends StatefulWidget {
  const QRDetectionScreen({super.key});

  @override
  State<QRDetectionScreen> createState() => _QRDetectionScreenState();
}

class _QRDetectionScreenState extends State<QRDetectionScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _lastScanned;
  bool _isTorchOn = false;

  // 🔍 STEP 1: Analyze QR content
  QRScanResult _analyzeQR(String raw) {
    final uri = Uri.tryParse(raw);

    if (uri == null) {
      return QRScanResult(
        risk: QRRiskLevel.unknown,
        reason: 'Invalid QR content',
      );
    }

    // Not a web link → usually safe
    if (!['http', 'https'].contains(uri.scheme)) {
      return QRScanResult(
        risk: QRRiskLevel.safe,
        reason: 'Not a web link',
      );
    }

    final suspiciousKeywords = [
      'login',
      'verify',
      'bank',
      'secure',
      'update',
      'account',
      'reward',
      'free',
      'claim',
    ];

    final lower = raw.toLowerCase();
    final containsSuspicious =
        suspiciousKeywords.any((k) => lower.contains(k));

    if (containsSuspicious) {
      return QRScanResult(
        risk: QRRiskLevel.high,
        reason: 'Suspicious keywords detected',
      );
    }

    // Very short URLs often hide redirects
    if (uri.host.length < 6) {
      return QRScanResult(
        risk: QRRiskLevel.suspicious,
        reason: 'Shortened or unclear domain',
      );
    }

    return QRScanResult(
      risk: QRRiskLevel.safe,
      reason: 'No obvious threat detected',
    );
  }

  // 📷 STEP 2: Handle scan result
  void _foundBarcode(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty || raw == _lastScanned) return;

    final result = _analyzeQR(raw);

    setState(() {
      _lastScanned = raw;
    });

    _showResult(raw, result);
  }

  // 🧾 STEP 3: Show result UI
  void _showResult(String raw, QRScanResult result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _riskHeader(result),
            const SizedBox(height: 12),
            Text(
              raw,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              result.reason,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 🔘 Action buttons
            if (result.risk != QRRiskLevel.high)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(raw);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text('Open Link'),
                ),
              ),

            if (result.risk == QRRiskLevel.high)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Close (Unsafe)'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _riskHeader(QRScanResult result) {
    Color color;
    String label;
    IconData icon;

    switch (result.risk) {
      case QRRiskLevel.safe:
        color = Colors.green;
        label = 'Safe QR Code';
        icon = Icons.check_circle;
        break;
      case QRRiskLevel.suspicious:
        color = Colors.orange;
        label = 'Suspicious QR Code';
        icon = Icons.warning_amber;
        break;
      case QRRiskLevel.high:
        color = Colors.red;
        label = 'High Risk QR Code';
        icon = Icons.dangerous;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown QR Code';
        icon = Icons.help_outline;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
      appBar: AppBar(
        title: const Text('QR Detection'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _foundBarcode,
      ),
    );
  }
}
