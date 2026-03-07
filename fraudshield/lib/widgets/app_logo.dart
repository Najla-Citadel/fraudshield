import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.withText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🛡️ Gradient Shield Icon
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF60A5FA), // Light Blue
                AppColors.primaryBlue, // Primary
                Color(0xFF3B82F6), // Darker Blue
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.shield_rounded, // Rounded shield looks softer
            size: size,
            color: Colors.white, // Required for ShaderMask
            shadows: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        // 🔐 Lock Icon inside (Optional, implemented as a Stack if needed, 
        // but for now simple Shield is cleaner. Let's add a small check/lock overlay if requested.
        // For now, sticking to the clean Gradient Shield).

        if (withText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'FraudShield',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
