import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FadeInList extends StatelessWidget {
  final List<Widget> children;
  final double verticalOffset;
  final Duration duration;

  const FadeInList({
    super.key,
    required this.children,
    this.verticalOffset = 50.0,
    this.duration = const Duration(milliseconds: 375),
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: duration,
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: verticalOffset,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}
