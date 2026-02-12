import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'points_history_screen.dart';
import 'rewards_catalog_screen.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_surface.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => PointsScreenState();
}

class PointsScreenState extends State<PointsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  int _balance = 0;

  String _petType = 'dog';
  bool _petJump = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Public method for external refresh (e.g., from HomeScreen tab tap)
  Future<void> refreshData() async {
    await _loadPoints();
    if (mounted) setState(() {});
  }

  // ================= INIT =================
  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadPet();
    await _loadPoints();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    _petType = prefs.getString('pet_type') ?? 'dog';
  }

  Future<void> _loadPoints() async {
    try {
      final res = await _api.getMyPoints();
      _balance = res['totalPoints'] ?? 0;
    } catch (e) {
      log('Error loading points: $e');
    }
  }

  String _petAnimation() => 'assets/animations/pet_$_petType.json';

  // ================= UI =================
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: AdaptiveScaffold(
        title: 'Points',
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _openPetSelector,
            tooltip: 'Choose Pet',
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // ⭐ CURRENT POINTS
                    GlassSurface(
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      borderColor: Colors.blue.withOpacity(0.3),
                      child: Column(
                        children: [
                          const Text(
                            'CURRENT POINTS',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_balance',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 🐾 PET + TAP ANIMATION
                    GestureDetector(
                      onTap: () {
                        setState(() => _petJump = true);
                        Future.delayed(
                          const Duration(milliseconds: 500),
                          () => setState(() => _petJump = false),
                        );
                      },
                      child: SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Subtle glow behind pet
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.08),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.08),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSlide(
                              offset: _petJump
                                  ? const Offset(0, -0.12)
                                  : Offset.zero,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              child: AnimatedScale(
                                scale: _petJump ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 450),
                                child: Lottie.asset(
                                  _petAnimation(),
                                  height: 260,
                                  repeat: true,
                                ),
                              ),
                            ),
                            if (_petJump)
                              const Positioned(
                                top: 0,
                                right: 60,
                                child: Text(
                                  '❤️',
                                  style: TextStyle(fontSize: 48),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 🎁 REDEEM POINTS
                    SizedBox(
                      width: double.infinity,
                      child: AdaptiveButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RewardsCatalogScreen(),
                            ),
                          );
                          _loadPoints(); // Refresh balance when coming back
                        },
                        text: 'Redeem Rewards',
                      ),
                    ),
  
                    const SizedBox(height: 16),
  
                    // 🕒 VIEW HISTORY
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PointsHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('View Point History'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
  
                    const SizedBox(height: 24),
  
                    // ✨ FOOTNOTE
                    const Text(
                      '✨ Login daily to keep your pet happy',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // ================= PET SELECTOR =================
  void _openPetSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for GlassSurface
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

////////////////////////////////////////////////////////////
/// GRADIENT BUTTON
////////////////////////////////////////////////////////////

Widget _gradientButton({
  required IconData icon,
  required String text,
  required Gradient gradient,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

////////////////////////////////////////////////////////////
/// PET CHOOSER (BOTTOM SHEET)
////////////////////////////////////////////////////////////

class PetChooser extends StatelessWidget {
  final Function(String) onSelect;

  const PetChooser({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
