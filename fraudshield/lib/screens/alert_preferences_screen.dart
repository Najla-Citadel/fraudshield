import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Preferences state
  bool _isActive = true;
  double _radiusKm = 15;
  final List<String> _selectedCategories = [];

  // Available categories
  final List<Map<String, dynamic>> _availableCategories = [
    {'id': 'e-commerce', 'label': 'E-Commerce & Shopping', 'icon': Icons.shopping_bag_outlined},
    {'id': 'investment', 'label': 'Investment & Crypto', 'icon': Icons.trending_up_rounded},
    {'id': 'job', 'label': 'Fake Job Offers', 'icon': Icons.work_outline_rounded},
    {'id': 'phishing', 'label': 'Phishing Links & SMS', 'icon': Icons.link_rounded},
    {'id': 'impersonation', 'label': 'Authority Impersonation', 'icon': Icons.local_police_outlined},
    {'id': 'romance', 'label': 'Romance Scams', 'icon': Icons.favorite_border_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await ApiService.instance.getAlertPreferences();
      if (mounted) {
        setState(() {
          _isActive = prefs['isActive'] ?? true;
          _radiusKm = (prefs['radiusKm'] ?? 15).toDouble();
          
          final List<dynamic> cats = prefs['categories'] ?? [];
          for (var c in cats) {
            _selectedCategories.add(c.toString());
          }
          
          // if new user with empty prefs, select top 3 by default
          if (_selectedCategories.isEmpty && prefs['isActive'] == null) {
            _selectedCategories.addAll(['e-commerce', 'investment', 'phishing']);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.subscribeToAlerts(
        categories: _selectedCategories,
        radiusKm: _radiusKm.toInt(),
        isActive: _isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Alert Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Master Switch
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Proactive Alerts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Receive warnings about trending scams', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                          ],
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                          activeColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  
                  AnimatedOpacity(
                    opacity: _isActive ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_isActive,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          const Text('LOCAL THREATS', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('Alert radius for scams reported near you', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('${_radiusKm.toInt()} km', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _radiusKm,
                                  min: 5,
                                  max: 50,
                                  divisions: 9,
                                  activeColor: AppColors.primaryBlue,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) => setState(() => _radiusKm = val),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          const Text('SCAM CATEGORIES', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('Select which type of threats you want to monitor', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                          const SizedBox(height: 16),
                          
                          ..._availableCategories.map((cat) {
                            final isSelected = _selectedCategories.contains(cat['id']);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _toggleCategory(cat['id']),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryBlue : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(cat['icon'], color: isSelected ? AppColors.primaryBlue : Colors.white54, size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          cat['label'],
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: (_isSaving || !_isActive && _selectedCategories.isEmpty) ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
