import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardsCatalogScreen extends StatefulWidget {
  const RewardsCatalogScreen({super.key});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _rewards = [];
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final [rewards, pointsData] = await Future.wait([
        _api.getRewards(),
        _api.getMyPoints(),
      ]);

      if (mounted) {
        setState(() {
          _rewards = List<Map<String, dynamic>>.from(rewards as List);
          _userPoints = (pointsData as Map)['totalPoints'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rewards: $e')),
        );
      }
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final pointsCost = reward['pointsCost'] as int;

    // Check if user has enough points
    if (_userPoints < pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient points! You need $pointsCost points.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reward['description']),
            const SizedBox(height: 16),
            Text(
              'Cost: $pointsCost points',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Your balance after: ${_userPoints - pointsCost} points',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform redemption
    try {
      await _api.redeemReward(reward['id']);

        if (mounted) {
          setState(() {
            _userPoints -= pointsCost; // Optimistic update
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully redeemed ${reward['name']}!'),
              backgroundColor: Colors.green,
            ),
          );

          // Background reload to ensure sync with server
          _loadData(showLoader: false);
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Catalog'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Points Balance Header
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_userPoints',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rewards List
                Expanded(
                  child: _rewards.isEmpty
                      ? const Center(
                          child: Text('No rewards available'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return _buildRewardCard(reward);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final name = reward['name'] as String;
    final description = reward['description'] as String;
    final pointsCost = reward['pointsCost'] as int;
    final type = reward['type'] as String;
    final canAfford = _userPoints >= pointsCost;

    // Icon based on type
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'subscription':
        icon = Icons.workspace_premium;
        iconColor = const Color(0xFFFFD700);
        break;
      case 'badge':
        icon = Icons.shield;
        iconColor = const Color(0xFF4CAF50);
        break;
      default:
        icon = Icons.card_giftcard;
        iconColor = const Color(0xFF2196F3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Points cost and redeem button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$pointsCost points',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: canAfford ? () => _redeemReward(reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? Colors.purple : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  canAfford ? 'Redeem' : 'Not enough',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
