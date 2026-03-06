import 'package:flutter/material.dart';
import 'dart:math';

class SecurityScoreRing extends StatefulWidget {
  final int score;
  final String status;
  final bool isScanning;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const SecurityScoreRing({
    super.key,
    required this.score,
    required this.status,
    required this.isScanning,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  State<SecurityScoreRing> createState() => _SecurityScoreRingState();
}

class _SecurityScoreRingState extends State<SecurityScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didUpdateWidget(SecurityScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _scanController.repeat();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _scanController.stop();
      _scanController.reset();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Color _getStatusColor(int score) {
    if (score >= 75) return const Color(0xFF10B981); // Emerald 500 (Green)
    if (score >= 50) return const Color(0xFFF59E0B); // Amber 500
    return const Color(0xFFEF4444); // Red 500
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isScanning ? null : widget.onTap,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Outer Glow / Blur (Pulsing when scanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                double pulse = widget.isScanning ? (0.1 + 0.1 * sin(_scanController.value * 2 * pi)) : 0.1;
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(widget.score).withOpacity(pulse),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // 2. Background Circle (Track)
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 16,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(05),
                ),
              ),
            ),

            // 3. Progress Arc (Gradient) - Rotates during scan
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.isScanning ? _scanController.value * 2 * pi : 0,
                  child: child,
                );
              },
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _GradientArcPainter(
                    percent: widget.isScanning ? 0.75 : widget.score / 100.0, // Show partial arc during scan
                    strokeWidth: 16,
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(widget.score),
                        _getStatusColor(widget.score).withOpacity(8),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Central Text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isScanning)
                  Text(
                    'SCANNING...',
                    style: TextStyle(
                      color: _getStatusColor(widget.score),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: _getStatusColor(widget.score), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(widget.score),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                widget.isScanning
                    ? AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          // Simple pulsing opacity based on scan cycle
                          double opacity = 0.3 + 0.7 * (0.5 * (1 + sin(_scanController.value * 4 * pi)));
                          return Opacity(
                            opacity: opacity,
                            child: const Text(
                              '...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          );
                        },
                      )
                    : Text(
                        '${widget.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  widget.isScanning ? 'Checking System...' : 'Security Score: ${widget.status}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // 5. Info Icon
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(5),
                  size: 20,
                ),
                onPressed: widget.onInfoTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Gradient gradient;

  _GradientArcPainter({
    required this.percent,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    // Start from top (-pi/2)
    // Draw arc based on percentage
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * percent;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientArcPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
