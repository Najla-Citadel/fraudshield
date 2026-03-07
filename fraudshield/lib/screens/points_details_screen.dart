import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.instance.getMyPoints();
      // Sync auth provider to get latest spendable/total points
      await context.read<AuthProvider>().refreshProfile();

      if (mounted) {
        setState(() {
          _transactions = res['transactions'] ?? [];
          _loading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      log('Error loading points details: $e');
      if (e.toString().contains('403')) {
        // User not authorized (likely email not verified)
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError =
                false; // We can still show cached points from ApiService query
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Note: Please verify your email to sync latest status.'),
                duration: Duration(seconds: 2)),
          );
        }
      } else if (mounted) {
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
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  AppColors.deepNavy, // Deep navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Points Details',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Future: Show points info/rules
            },
          ),
        ],
      ),
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

    return AnimationLimiter(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const SizedBox(height: 20),
              _buildSummaryHeader(),
              const SizedBox(height: 24),
              _buildLeaderboardCard(),
              const SizedBox(height: 32),
              _buildHistoryHeader(),
              const SizedBox(height: 16),
              _buildTransactionHistory(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final points = context.watch<AuthProvider>().user?.profile?.points ?? 0;
    final totalPoints =
        context.watch<AuthProvider>().user?.profile?.totalPoints ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Match regular cards
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPENDABLE POINTS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'PTS',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white.withOpacity(0.1),
                child: const SizedBox(height: 36), // Minimum height for divider
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LIFETIME EARNINGS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPoints PTS',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress toward next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _calculateTier(totalPoints),
                    style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Next level at ${_getNextTierTarget(totalPoints)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getTierProgress(totalPoints),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentGreen),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTier(int totalPoints) {
    if (totalPoints >= 10000) return 'DIAMOND PROTECTOR';
    if (totalPoints >= 5000) return 'GOLD PROTECTOR';
    if (totalPoints >= 1000) return 'SILVER PROTECTOR';
    return 'BRONZE PROTECTOR';
  }

  int _getNextTierTarget(int totalPoints) {
    if (totalPoints >= 10000) return 20000;
    if (totalPoints >= 5000) return 10000;
    if (totalPoints >= 1000) return 5000;
    return 1000;
  }

  double _getTierProgress(int totalPoints) {
    int target = _getNextTierTarget(totalPoints);
    int start = 0;
    if (totalPoints >= 5000)
      start = 5000;
    else if (totalPoints >= 1000) start = 1000;

    double progress = (totalPoints - start) / (target - start);
    return progress.clamp(0.0, 1.0);
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
              child: const Icon(Icons.emoji_events_rounded,
                  color: AppColors.accentGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Leaderboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See how you rank against other protectors.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.2), size: 14),
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
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
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
