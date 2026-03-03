import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
<<<<<<< HEAD
import '../constants/colors.dart';
=======
>>>>>>> dev-ui2

class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry margin;

  const SkeletonCard({
    super.key,
    this.height,
    this.margin = const EdgeInsets.only(bottom: 16, left: 16, right: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: const Color(0xFF1E293B), // Dark Slate
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.15),
=======
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E293B),
        highlightColor: const Color(0xFF334155),
>>>>>>> dev-ui2
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
<<<<<<< HEAD
                      color: Colors.white,
=======
                      color: Colors.white.withValues(alpha: 0.1),
>>>>>>> dev-ui2
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and subtitle lines
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
<<<<<<< HEAD
                        Container(width: 150, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, color: Colors.white),
=======
                        Container(
                            width: 150,
                            height: 16,
                            color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 8),
                        Container(
                            width: 100,
                            height: 12,
                            color: Colors.white.withValues(alpha: 0.1)),
>>>>>>> dev-ui2
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
<<<<<<< HEAD
              Container(width: double.infinity, height: 12, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 200, height: 12, color: Colors.white),
=======
              Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              Container(
                  width: 200,
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.1)),
>>>>>>> dev-ui2
            ],
          ),
        ),
      ),
    );
  }
}
