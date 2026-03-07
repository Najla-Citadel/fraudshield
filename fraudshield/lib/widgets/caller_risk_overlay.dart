import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../app_router.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';

class CallerRiskOverlay extends StatefulWidget {
  final Map<String, dynamic>? callerData;
  final bool isSystemOverlay;

  const CallerRiskOverlay({
    super.key,
    this.callerData,
    this.isSystemOverlay = false,
  });

  @override
  State<CallerRiskOverlay> createState() => _CallerRiskOverlayState();
}

class _CallerRiskOverlayState extends State<CallerRiskOverlay> {
  // ── Helpers ───────────────────────────────────────────

  String get _phoneNumber =>
      widget.callerData?['phoneNumber'] as String? ?? 'Unknown Number';
  int get _score => (widget.callerData?['score'] as num?)?.toInt() ?? 0;
  String get _level => widget.callerData?['level'] as String? ?? 'low';
  int get _communityReports =>
      (widget.callerData?['communityReports'] as num?)?.toInt() ?? 0;
  List<String> get _categories =>
      (widget.callerData?['categories'] as List?)?.cast<String>() ?? [];
  bool get _isLoading => widget.callerData?['loading'] == true;
  String? get _verifiedEntity =>
      widget.callerData?['verifiedEntity'] as String?;

  Color get _levelColor {
    switch (_level) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  String get _levelLabel {
    switch (_level) {
      case 'critical':
        return 'Critical Risk ⚠️';
      case 'high':
        return 'High Risk 🚨';
      case 'medium':
        return 'Suspicious 🔶';
      default:
        return 'Looks Safe ✅';
    }
  }

  IconData get _levelIcon {
    switch (_level) {
      case 'critical':
      case 'high':
        return Icons.gpp_bad_rounded;
      case 'medium':
        return Icons.gpp_maybe_rounded;
      default:
        return Icons.verified_user_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Frosted glass background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.75)),
            ),
          ),

          // Pulsing ring for high risk
          if (!_isLoading && (_level == 'high' || _level == 'critical'))
            const _PulsingRing(),

          // Main card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'INCOMING CALL',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _phoneNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
        border: Border.all(
          color: _isLoading ? Colors.white12 : _levelColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: DesignTokens.shadows.md,
      ),
      child: _isLoading ? _buildLoading() : _buildContent(context),
    );
  }

  Widget _buildLoading() {
    return const Column(
      children: [
        const AppLoadingIndicator(color: Colors.white38),
        SizedBox(height: 16),
        Text(
          'Checking caller database...',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HANG UP NOW CTA (Critical Only)
        if (_level == 'critical') ...[
          InkWell(
            onTap: () => _forceDismiss(context),
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                boxShadow: DesignTokens.shadows.md,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'HANG UP NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Risk Icon
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _levelColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_levelIcon, color: _levelColor, size: 44),
        ),
        const SizedBox(height: 14),

        // Verified Entity
        if (_verifiedEntity != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
              border:
                  Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF22C55E), size: 16),
                const SizedBox(width: 6),
                Text(
                  _verifiedEntity!,
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Level label
        Text(
          _levelLabel,
          style: TextStyle(
            color: _levelColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),

        // Score bar
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
          child: LinearProgressIndicator(
            value: _score / 100,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Risk Score: $_score/100',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                )),
            if (_communityReports > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Text(
                  '$_communityReports report${_communityReports > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ),

        // Categories
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _categories
                .take(4)
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(c,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          )),
                    ))
                .toList(),
          ),

          // Scam Script Preview Banner
          _buildScamScriptBanner(),
        ],

        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),

        // Action buttons - Row 1
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.mic_rounded,
                label: 'Record & Analyze',
                color: DesignTokens.colors.primary,
                onTap: () => _handleAction(context, 'record'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.flag_rounded,
                label: 'Report Scam',
                color: const Color(0xFFF59E0B),
                onTap: () => _handleAction(context, 'report'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Action buttons - Row 2
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.block_rounded,
                label: 'How to Block',
                color: Colors.redAccent,
                onTap: () => _showBlockGuide(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.close_rounded,
                label: 'Dismiss',
                color: Colors.white38,
                onTap: () => _handleAction(context, 'dismiss'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScamScriptBanner() {
    String message = '';
    if (_categories.contains('Bank Officer') ||
        _categories.contains('Fake Bank Officer')) {
      message =
          'Scammers claiming to be bank officers NEVER ask for your OTP or TAC number.';
    } else if (_categories.contains('Government Agency') ||
        _categories.contains('Police / Court')) {
      message =
          'Government agencies NEVER call to demand immediate money transfers.';
    } else if (_categories.contains('Parcel/Courier') ||
        _categories.contains('Post Laju')) {
      message =
          'Delivery companies NEVER charge redelivery fees via phone call.';
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFCD34D),
                fontSize: 12,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _forceDismiss(BuildContext context) async {
    if (widget.isSystemOverlay) {
      await FlutterOverlayWindow.closeOverlay();
    } else {
      NotificationService.instance.dismissCallerRisk();
    }
  }

  void _handleAction(BuildContext context, String action) async {
    // Friction for High/Critical risk dismissals
    if (action == 'dismiss' && _score >= 55) {
      bool shouldDismiss = await _showFrictionDialog(context);
      if (!shouldDismiss) return;
    }

    if (widget.isSystemOverlay) {
      if (action == 'dismiss') {
        await FlutterOverlayWindow.closeOverlay();
      } else if (action == 'record') {
        // Send message to main app to launch voice scan, then close overlay
        await FlutterOverlayWindow.shareData('launch_voice_scan');
        await FlutterOverlayWindow.closeOverlay();
      } else {
        await FlutterOverlayWindow.closeOverlay();
      }
    } else {
      NotificationService.instance.dismissCallerRisk();
      if (action == 'record') {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isSubscribed) {
          AppRouter.navigatorKey.currentState?.pushNamed(
            '/voice-scan',
            arguments: {'autoStart': true},
          );
        } else {
          AppRouter.navigatorKey.currentState?.pushNamed('/subscription');
        }
      } else if (action == 'report') {
        AppRouter.navigatorKey.currentState?.pushNamed('/report');
      }
    }
  }

  Future<bool> _showFrictionDialog(BuildContext context) async {
    // In system overlay, showing a dialog inside the overlay window Material works,
    // but requires a Navigator. Since we are inside a simple Material, showDialog
    // requires a Navigator.
    // If there is no Navigator in the system overlay, we might need to handle it differently.
    // Assuming root widget in overlayMain sets up a MaterialApp or Router, showDialog will work.

    // For safety, let's wrap in a try-catch. If it fails, fallback to force dismiss.
    try {
      bool result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                  side: const BorderSide(color: Color(0xFFDC2626), width: 2)),
              title: const Row(
                children: [
                  Icon(Icons.gpp_bad_rounded, color: Color(0xFFDC2626)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Risk Warning',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: Text(
                'This caller is flagged as High/Critical Risk.\nAre you sure you want to continue?',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), height: 1.5),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowAlignment: OverflowBarAlignment.center,
              actionsOverflowDirection: VerticalDirection.down,
              actions: [
                AppButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  label: 'Keep Hanging Up',
                  variant: AppButtonVariant.primary,
                  width: double.infinity,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('I Understand, Continue',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      return result;
    } catch (e) {
      // If error (e.g., no Navigator), fallback to true to unblock the user.
      return true;
    }
  }

  void _showBlockGuide(BuildContext context) {
    try {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radii.lg)),
          title: const Text('Block This Number',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To block this caller from your phone:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _blockStep('1', 'Open your Phone app'),
              _blockStep('2', 'Go to Recent Calls'),
              _blockStep('3', 'Tap & hold "$_phoneNumber"'),
              _blockStep('4', 'Select "Block / Report Spam"'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got It',
                  style: TextStyle(color: DesignTokens.colors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Ignore if no navigator available.
    }
  }

  Widget _blockStep(String num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignTokens.colors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(num,
                  style: TextStyle(
                      color: DesignTokens.colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ))),
          ],
        ),
      );
}

// ── Action Button ─────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radii.md),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing Ring Animation ────────────────────────────────

class _PulsingRing extends StatefulWidget {
  const _PulsingRing();

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _anim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.3 * (1 - _anim.value)),
              width: 30 * _anim.value,
            ),
          ),
        ),
      ),
    );
  }
}
