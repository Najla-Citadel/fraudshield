import 'dart:developer';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';

class PointsDetailsScreen extends StatefulWidget {
  const PointsDetailsScreen({super.key});

  @override
  State<PointsDetailsScreen> createState() => _PointsDetailsScreenState();
}

class _PointsDetailsScreenState extends State<PointsDetailsScreen> {
  bool _loading = true;
  bool _hasError = false;
  int _balance = 0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.instance.getMyPoints();
      if (mounted) {
        setState(() {
          _balance = res['totalPoints'] ?? 0;
          _transactions = res['transactions'] ?? [];
          _loading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      log('Error loading points details: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Points Details',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            // Future: Show points info/rules
          },
        ),
      ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return ErrorState(onRetry: () {
        setState(() {
          _loading = true;
          _hasError = false;
        });
        _loadData();
      });
    }

    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SkeletonCard(height: 200, margin: EdgeInsets.zero),
            const SizedBox(height: 32),
            const SkeletonCard(height: 80, margin: EdgeInsets.zero),
            const SizedBox(height: 16),
            const SkeletonCard(height: 80, margin: EdgeInsets.zero),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildLeaderboardCard(),
          const SizedBox(height: 32),
          _buildHistoryHeader(),
          const SizedBox(height: 16),
          _buildTransactionHistory(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2633),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F2633),
            const Color(0xFF0F2633).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'YOUR BALANCE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$_balance ',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'PTS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.shield, color: AppColors.accentGreen, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Silver Protector Status',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve reached Silver Protector status this month. Keep it up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/leaderboard'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.accentGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Leaderboard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See how you rank against other protectors.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'HISTORY',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          'Filter',
          style: TextStyle(
            color: AppColors.accentGreen.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            'No transaction history yet.',
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      );
    }

    // Grouping logic
    final now = DateTime.now();
    final todayTransactions = <dynamic>[];
    final thisMonthTransactions = <dynamic>[];
    final olderTransactions = <dynamic>[];

    for (var tx in _transactions) {
      final date = DateTime.parse(tx['createdAt']);
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        todayTransactions.add(tx);
      } else if (date.year == now.year && date.month == now.month) {
        thisMonthTransactions.add(tx);
      } else {
        olderTransactions.add(tx);
      }
    }

    return Column(
      children: [
        if (todayTransactions.isNotEmpty) ...[
          _buildGroupHeader('TODAY'),
          ...todayTransactions.map((tx) => _buildTransactionItem(tx)),
          const SizedBox(height: 24),
        ],
        if (thisMonthTransactions.isNotEmpty) ...[
          _buildGroupHeader('THIS MONTH'),
          ...thisMonthTransactions.map((tx) => _buildTransactionItem(tx)),
          const SizedBox(height: 24),
        ],
        if (olderTransactions.isNotEmpty) ...[
          _buildGroupHeader('OLDER'),
          ...olderTransactions.map((tx) => _buildTransactionItem(tx)),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final amount = tx['amount'] as int;
    final isPositive = amount > 0;
    final date = DateTime.parse(tx['createdAt']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForDescription(tx['description'] ?? ''),
              color: isPositive ? AppColors.accentGreen : AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Points Update',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$amount',
            style: TextStyle(
              color: isPositive ? AppColors.accentGreen : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForDescription(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('report')) return Icons.shield;
    if (d.contains('check')) return Icons.check_circle_outline;
    if (d.contains('premium')) return Icons.star_outline;
    if (d.contains('alert')) return Icons.sensors;
    if (d.contains('referral')) return Icons.group_outlined;
    return Icons.star;
  }
}
