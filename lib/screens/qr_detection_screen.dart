// lib/screens/qr_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';

class QRDetectionScreen extends StatefulWidget {
  const QRDetectionScreen({super.key});

  @override
  State<QRDetectionScreen> createState() => _QRDetectionScreenState();
}

class _QRDetectionScreenState extends State<QRDetectionScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _lastScanned;
  bool _isTorchOn = false;

  void _foundBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    // avoid duplicate rapid scans
    if (_lastScanned == raw) return;

    setState(() {
      _lastScanned = raw;
    });

    // Example: show result and provide actions
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scanned QR', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(raw),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // optionally open URL, copy, etc.
              },
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              final newVal = !_isTorchOn;
              await _controller.toggleTorch();
              setState(() => _isTorchOn = newVal);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            //allowDuplicates: false,
            onDetect: _foundBarcode,
          ),
          if (_lastScanned != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: Card(
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Last: ${_lastScanned!}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
