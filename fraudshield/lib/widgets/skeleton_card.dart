import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = margin ?? EdgeInsets.only(
      bottom: DesignTokens.spacing.lg, 
      left: DesignTokens.spacing.lg, 
      right: DesignTokens.spacing.lg
    );
    
    return Container(
      margin: effectiveMargin,
      height: height,
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Shimmer.fromColors(
        baseColor: Color(0xFF1E293B),
        highlightColor: Color(0xFF334155),
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Title and subtitle lines
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 150,
                            height: 16,
                            color: Colors.white.withOpacity(0.1)),
                        SizedBox(height: 8),
                        Container(
                            width: 100,
                            height: 12,
                            color: Colors.white.withOpacity(0.1)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white.withOpacity(0.1)),
              SizedBox(height: 8),
              Container(
                  width: 200,
                  height: 12,
                  color: Colors.white.withOpacity(0.1)),
            ],
          ),
        ),
      ),
    );
  }
}
