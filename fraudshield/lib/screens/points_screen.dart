import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'points_history_screen.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Points'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _openPetSelector,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9ED6FF),
                    Color(0xFFEAF6FF),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ⭐ CURRENT POINTS
                    const Text(
                      'CURRENT POINTS',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF355C7D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_balance',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3A5F),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🐾 PET + TAP ANIMATION
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _petJump = true);
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () => setState(() => _petJump = false),
                            );
                          },
                          child: AnimatedSlide(
                            offset: _petJump
                                ? const Offset(0, -0.12)
                                : Offset.zero,
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutBack,
                            child: AnimatedScale(
                              scale: _petJump ? 1.08 : 1.0,
                              duration:
                                  const Duration(milliseconds: 450),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Lottie.asset(
                                    _petAnimation(),
                                    height: 260,
                                    repeat: true,
                                  ),
                                  if (_petJump)
                                    const Positioned(
                                      top: 12,
                                      right: 16,
                                      child: Text(
                                        '❤️',
                                        style:
                                            TextStyle(fontSize: 36),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 🎁 REDEEM POINTS
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: _gradientButton(
                        icon: Icons.card_giftcard,
                        text: 'Redeem Points Now',
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEC6EAD),
                            Color(0xFF8F6ED5),
                          ],
                        ),
                        onTap: () {
                          // TODO: Navigate to redeem / subscription screen
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🕒 VIEW HISTORY
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: _gradientButton(
                        icon: Icons.history,
                        text: 'View Points History',
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6A85F1),
                            Color(0xFF8F6ED5),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PointsHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✨ FOOTNOTE
                    const Text(
                      '✨ Login daily to keep your pet happy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5B7C99),
                      ),
                    ),

                    const SizedBox(height: 24),
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
