import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CommunityMapCard extends StatefulWidget {
  final int threatCount;
  final String locationName;

  const CommunityMapCard({
    super.key,
    this.threatCount = 12, // Default mock if not provided
    this.locationName = 'Klang Valley',
  });

  @override
  State<CommunityMapCard> createState() => _CommunityMapCardState();
}

class _CommunityMapCardState extends State<CommunityMapCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/scam-map'),
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 1. Radar Pulse Background
              _buildRadarBackground(),

              // 2. Gradient Overlay for Typography (Soft White Fade)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Live Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLiveBadge(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.maximize, color: Color(0xFF64748B), size: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Stat Section
                    const Text(
                      'Live Threat Scanner',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.threatCount} Clusters in ${widget.locationName}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(LucideIcons.navigation, color: AppColors.primaryBlue, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Tap to view interactive heat map',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Static grid lines
            _buildGrid(),
            
            // Pulse 1
            Container(
              width: 300 * _pulseAnimation.value,
              height: 300 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.5 * (1.0 - _pulseAnimation.value)),
                  width: 2,
                ),
              ),
            ),
            
            // Pulse 2 (delayed offset)
            if (_pulseAnimation.value > 0.5)
              Container(
                width: 300 * (_pulseAnimation.value - 0.5) * 2,
                height: 300 * (_pulseAnimation.value - 0.5) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.5 * (1.0 - (_pulseAnimation.value - 0.5) * 2)),
                    width: 1,
                  ),
                ),
              ),

            // Center Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Soft Blue
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)), // Light Blue Border
              ),
              child: const Icon(LucideIcons.radar, color: AppColors.primaryBlue, size: 40),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid() {
    return Opacity(
      opacity: 0.1,
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: RadarGridPainter(),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1) // Slate 300 for grid lines
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw circles
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, i * 40.0, paint..style = PaintingStyle.stroke);
    }

    // Actually let's just draw 4 main lines
    
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
