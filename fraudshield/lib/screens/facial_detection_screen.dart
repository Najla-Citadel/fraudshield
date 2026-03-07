// lib/screens/facial_detection_screen.dart
import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FacialDetectionScreen extends StatefulWidget {
  const FacialDetectionScreen({super.key});

  @override
  State<FacialDetectionScreen> createState() => _FacialDetectionScreenState();
}

class _FacialDetectionScreenState extends State<FacialDetectionScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;

  void _startDetection() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing facial features...';
    });

    // Simulate detection
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Identity Verified Successfully';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Facial Verification',
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔳 SCANNER FRAME
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isSuccess 
                          ? DesignTokens.colors.success 
                          : Colors.white.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.black26,
                        child: Icon(
                          _isSuccess ? Icons.face_retouching_natural : Icons.face_outlined,
                          size: 120,
                          color: _isSuccess 
                            ? DesignTokens.colors.success 
                            : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    const SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              
              // 📄 STATUS
              Text(
                _statusMessage ?? 'Align your face within the circle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? DesignTokens.colors.success : Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Used for high-security actions and account recovery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // 🔘 ACTION
              if (!_isProcessing && !_isSuccess)
                AppButton(
                  label: 'Start Verification',
                  onPressed: _startDetection,
                )
              else if (_isSuccess)
                AppButton(
                  label: 'Back to Safety',
                  onPressed: () => Navigator.pop(context),
                  icon: LucideIcons.chevronLeft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
