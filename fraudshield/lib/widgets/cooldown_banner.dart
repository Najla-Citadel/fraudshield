import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class CoolDownBanner extends StatefulWidget {
  const CoolDownBanner({super.key});

  @override
  State<CoolDownBanner> createState() => _CoolDownBannerState();
}

class _CoolDownBannerState extends State<CoolDownBanner> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final endsAt = NotificationService.instance.coolDownEndsAt;
    if (endsAt == null) return;

    _remaining = endsAt.difference(DateTime.now());
    if (_remaining.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.instance.dismissCoolDown();
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      setState(() {
        _remaining = endsAt.difference(now);
      });

      if (_remaining.isNegative) {
        timer.cancel();
        NotificationService.instance.dismissCoolDown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) return const SizedBox.shrink();

    final minutes = _remaining.inMinutes;
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            border: const Border(
              left: BorderSide(color: Color(0xFFDC2626), width: 4),
            ),
            boxShadow: DesignTokens.shadows.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.timer_outlined,
                  color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cool-Down Period ($minutes:$seconds)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🛑 Do not make any transfers. Scam calls often create false urgency!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white54, size: 20),
                onPressed: () {
                  NotificationService.instance.dismissCoolDown();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
