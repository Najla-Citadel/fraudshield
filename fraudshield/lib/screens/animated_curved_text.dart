import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedCurvedText extends StatefulWidget {
  final String text;
  final double radius;
  final TextStyle style;

  const AnimatedCurvedText({
    super.key,
    required this.text,
    required this.radius,
    required this.style,
  });

  @override
  State<AnimatedCurvedText> createState() => _AnimatedCurvedTextState();
}

class _AnimatedCurvedTextState extends State<AnimatedCurvedText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.radius * 2, widget.radius),
          painter: _HalfCircleTextPainter(
            text: widget.text,
            radius: widget.radius,
            style: widget.style,
            glowPhase: _controller.value,
          ),
        );
      },
    );
  }
}

class _HalfCircleTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle style;
  final double glowPhase;

  _HalfCircleTextPainter({
    required this.text,
    required this.radius,
    required this.style,
    required this.glowPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final runes = text.runes.toList(); // ✅ FIXED UTF-16 ISSUE

    final angleStep = pi / (runes.length + 1);
    double angle = pi + angleStep;

    for (final rune in runes) {
      final char = String.fromCharCode(rune);

      final offset = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle + pi / 2);

      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.4 + 0.3 * sin(glowPhase * 2 * pi))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final tp = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawCircle(Offset.zero, 14, glowPaint);
      tp.paint(
        canvas,
        Offset(-tp.width / 2, -tp.height / 2),
      );

      canvas.restore();
      angle += angleStep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
