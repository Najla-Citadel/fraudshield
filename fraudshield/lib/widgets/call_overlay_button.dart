import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class CallOverlayButton extends StatelessWidget {
  const CallOverlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FlutterOverlayWindow.closeOverlay();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              boxShadow: DesignTokens.shadows.sm,
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: Color(0xFF38BDF8),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
