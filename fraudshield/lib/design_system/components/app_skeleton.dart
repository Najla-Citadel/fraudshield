import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.child,
  });

  /// A square/rectangular skeleton
  factory AppSkeleton.card({
    double? width,
    double? height,
    double borderRadius = 16,
  }) =>
      AppSkeleton(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );

  /// A circular skeleton for avatars or icons
  factory AppSkeleton.circle({
    required double size,
  }) =>
      AppSkeleton(
        width: size,
        height: size,
        borderRadius: size / 2,
      );

  /// A thin skeleton for text lines
  factory AppSkeleton.text({
    double? width,
    double height = 14,
    double borderRadius = 4,
  }) =>
      AppSkeleton(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        );
      },
    );
  }
}
