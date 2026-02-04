import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../services/supabase_service.dart';
import 'points_history_screen.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  int _balance = 0;
  String? _petType;
  bool _claimedToday = false;

  static const double _orbSize = 340;

  late AnimationController _spinCtrl;
  bool _petJump = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _init();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  // ================= INIT =================
  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadPet();
    await _checkDailyReward();
    await _loadPoints();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    _petType = prefs.getString('pet_type');
    _claimedToday = prefs.getString('last_daily_reward') == _todayKey();
  }

  Future<void> _loadPoints() async {
    _balance = await SupabaseService.instance.getMyPoints();
  }

  Future<void> _checkDailyReward() async {
    if (_petType == null || _claimedToday) return;
    final prefs = await SharedPreferences.getInstance();
    await SupabaseService.instance.addPoints(
      change: 1,
      reason: 'Daily pet care bonus',
    );
    await prefs.setString('last_daily_reward', _todayKey());
    _claimedToday = true;
  }

  String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  String _petAnimation() =>
      'assets/animations/pet_${_petType ?? 'dog'}.json';

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        title: const Text('Points'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _openPetSelector,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),

                // ⭐ BALANCE
                Column(
                  children: [
                    const Text(
                      'CURRENT POINTS',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_balance',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 🫧 ANIMATED ORB
                SizedBox(
                  height: _orbSize + 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔁 Rotating dashed ring
                      AnimatedBuilder(
                        animation: _spinCtrl,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: _spinCtrl.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(_orbSize, _orbSize),
                              painter: _RingPainter(),
                            ),
                          );
                        },
                      ),

                      // 🌈 Pulsing orb
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.95, end: 1.05),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (_, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: CustomPaint(
                          size: const Size(_orbSize - 30, _orbSize - 30),
                          painter: _OrbPainter(),
                        ),
                      ),

                      
                     /* CustomPaint(
                        size: const Size(_orbSize + 40, _orbSize + 40),
                        painter: _CurvedTextPainter(
                          text: _claimedToday
                              ? '✦ Your pet is happy today ✦'
                              : '✧ Come back tomorrow ✧',
                        ),
                      ),
                      */

                      // 🐾 PET (tap jump)
                      GestureDetector(
                        onTap: () {
                          setState(() => _petJump = true);
                          Future.delayed(const Duration(milliseconds: 500),
                              () => setState(() => _petJump = false));
                        },
                        child: AnimatedSlide(
                          offset: _petJump
                              ? const Offset(0, -0.15)
                              : Offset.zero,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          child: AnimatedScale(
                            scale: _petJump ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Lottie.asset(
                                  _petAnimation(),
                                  height: 240,
                                ),
                                if (_petJump)
                                  const Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Text('❤️',
                                        style: TextStyle(fontSize: 35)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 🔘 VIEW HISTORY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PointsHistoryScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'View Points History',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  '✨ Login daily to keep your pet happy',
                  style: TextStyle(color: Colors.black45),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ================= PET SELECTOR =================
  void _openPetSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PetChooser(onSelect: _savePet),
    );
  }

  Future<void> _savePet(String pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pet_type', pet);
    if (!mounted) return;
    Navigator.pop(context);
    await _init();
  }
}

////////////////////////////////////////////////////////////////
/// PAINTERS
////////////////////////////////////////////////////////////////

class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.blue.withOpacity(0.15),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CurvedTextPainter extends CustomPainter {
  final String text;
  _CurvedTextPainter({required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - 20;
    final center = Offset(size.width / 2, size.height / 2);
    const style = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      color: Colors.orange,
    );

    final chars = text.split('');
    final angleStep = pi / (chars.length + 2);
    double angle = pi * 1.2;

    for (final ch in chars) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final pos = Offset(
        center.dx + radius * cos(angle) - tp.width / 2,
        center.dy + radius * sin(angle) - tp.height / 2,
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
      angle += angleStep;
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

////////////////////////////////////////////////////////////////
/// PET CHOOSER (BOTTOM SHEET)
////////////////////////////////////////////////////////////////

class PetChooser extends StatelessWidget {
  final Function(String) onSelect;

  const PetChooser({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Your Companion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _pet(context, 'dog', '🐶'),
              _pet(context, 'cat', '🐱'),
              _pet(context, 'owl', '🦉'),
              _pet(context, 'fish', '🐟'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pet(BuildContext context, String type, String emoji) {
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 6),
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

