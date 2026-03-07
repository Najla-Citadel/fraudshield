import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  
  const AnimatedBackground({
    super.key, 
    this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Define gradient colors based on theme
    final color1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF); // Slate 900 / Sky 50
    final color2 = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE); // Blue 900 / Blue 100
    final color3 = isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF); // Indigo 900 / Indigo 100

    return Stack(
      children: [
        // Base layer
        Container(color: color1),
        
        // Animated gradient orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BackgroundPainter(
                progress: _controller.value,
                color1: color1,
                color2: color2,
                color3: color3,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Glass overlay for texture (optional noise could be added here)
        
        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final Color color3;

  _BackgroundPainter({
    required this.progress, 
    required this.color1, 
    required this.color2, 
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Orb 1: Moving top-left to center
    final offset1 = Offset(
      size.width * (0.2 + 0.3 * math.sin(progress * math.pi)),
      size.height * (0.2 + 0.2 * math.cos(progress * math.pi)),
    );
    paint.color = color2.withOpacity(0.4);
    canvas.drawCircle(offset1, size.width * 0.6, paint);

    // Orb 2: Moving bottom-right to center
    final offset2 = Offset(
      size.width * (0.8 - 0.3 * math.sin(progress * math.pi)),
      size.height * (0.8 - 0.2 * math.cos(progress * math.pi)),
    );
    paint.color = color3.withOpacity(0.4);
    canvas.drawCircle(offset2, size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color1 != color1 ||
           oldDelegate.color2 != color2 ||
           oldDelegate.color3 != color3;
  }
}
