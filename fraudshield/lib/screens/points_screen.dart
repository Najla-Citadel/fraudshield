import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'points_history_screen.dart';
import 'rewards_catalog_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.pets, color: Colors.white),
            onPressed: _openPetSelector,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ⭐ CURRENT POINTS
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'CURRENT POINTS',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_balance',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🐾 PET + TAP ANIMATION
                  GestureDetector(
                    onTap: () {
                      setState(() => _petJump = true);
                      Future.delayed(
                        const Duration(milliseconds: 500),
                        () => setState(() => _petJump = false),
                      );
                    },
                    child: Container(
                      height: 260,
                      alignment: Alignment.center,
                      child: AnimatedSlide(
                        offset: _petJump
                            ? const Offset(0, -0.12)
                            : Offset.zero,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        child: AnimatedScale(
                          scale: _petJump ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 450),
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
                                    style: TextStyle(fontSize: 36),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🎁 REDEEM POINTS
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RewardsCatalogScreen(),
                          ),
                        );
                        _loadPoints(); // Refresh balance when coming back
                      },
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Redeem Points Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 12),
  
                  // 🕒 VIEW HISTORY
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PointsHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Points History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 16),
  
                  // ✨ FOOTNOTE
                  const Text(
                    '✨ Login daily to keep your pet happy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
  
                  const SizedBox(height: 24),
                ],
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
