import 'package:flutter/material.dart';

class FadeInSlideUp extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInSlideUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    if (delay == Duration.zero) {
      return _buildAnimation();
    }
    
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Return invisible box with roughly the same size if possible,
          // or just opacity 0
          return Opacity(
            opacity: 0.0,
            child: child,
          );
        }
        return _buildAnimation();
      },
    );
  }

  Widget _buildAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCirc,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
