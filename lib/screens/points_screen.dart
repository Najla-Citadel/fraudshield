// lib/screens/points_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/primary_button.dart';
import 'points_history_screen.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  int _balance = 0;
  String? _petType;
  bool _claimedToday = false;
  static const double _orbSize = 300;

  late AnimationController _spinCtrl;
  bool _petJump = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _init();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

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
    await SupabaseService.instance.addPoints(change: 1, reason: 'Daily pet care bonus');
    await prefs.setString('last_daily_reward', _todayKey());
    _claimedToday = true;
  }

  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);
  String _petAnimation() => 'assets/animations/pet_${_petType ?? 'dog'}.json';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Points & Rewards'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pets, color: AppColors.primary),
            onPressed: _openPetSelector,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: AppSpacing.l),

                // ⭐ TOTAL POINTS
                Column(
                  children: [
                    Text('TOTAL POINTS', style: AppTypography.bodyS.copyWith(letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text('$_balance', style: AppTypography.h1.copyWith(fontSize: 48, color: AppColors.primary)),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // 🫧 ANIMATED ORB w/ PET
                SizedBox(
                  height: _orbSize + 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring
                      AnimatedBuilder(
                        animation: _spinCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: _spinCtrl.value * 2 * pi,
                          child: CustomPaint(
                            size: const Size(_orbSize, _orbSize),
                            painter: _RingPainter(),
                          ),
                        ),
                      ),
                      
                      // Glow
                      Container(
                        width: _orbSize - 40,
                        height: _orbSize - 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                             BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                      ),

                      // Pet
                      GestureDetector(
                        onTap: () {
                          setState(() => _petJump = true);
                          Future.delayed(const Duration(milliseconds: 500), () => setState(() => _petJump = false));
                        },
                        child: AnimatedScale(
                          scale: _petJump ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Lottie.asset(_petAnimation(), height: 200),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 🔘 HISTORY BUTTON
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: PrimaryButton(
                    label: 'View Points History',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsHistoryScreen())),
                  ),
                ),

                const SizedBox(height: AppSpacing.m),
                
                Text(
                  _claimedToday ? '✨ You claimed your daily bonus!' : '✨ Come back tomorrow for more points',
                  style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  void _openPetSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PetChooser(onSelect: _savePet),
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

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    // Draw dashed circle logically (simplified as solid arc for now or implement dash logic)
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PetChooser extends StatelessWidget {
  final Function(String) onSelect;
  const _PetChooser({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choose Companion', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _petItem('dog', '🐶'),
              _petItem('cat', '🐱'),
              _petItem('owl', '🦉'),
              _petItem('fish', '🐟'),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }

  Widget _petItem(String type, String emoji) {
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(type.toUpperCase(), style: AppTypography.bodyS.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
