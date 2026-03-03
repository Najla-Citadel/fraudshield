import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  Map<String, dynamic>? _myRank;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getLeaderboard(),
        ApiService.instance.getMyRank(),
      ]);
      
      if (mounted) {
        setState(() {
          _leaderboard = results[0] as List<dynamic>;
          _myRank = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'GLOBAL LEADERBOARD',
          style: theme.textTheme.labelMedium?.copyWith(
<<<<<<< HEAD
            color: AppColors.textLight.withOpacity(0.7),
=======
            color: AppColors.textLight.withValues(alpha: 0.7),
>>>>>>> dev-ui2
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : Stack(
              children: [
                Column(
                  children: [
                    _buildTopThree(),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 24),
                        decoration: BoxDecoration(
<<<<<<< HEAD
                          color: Colors.white.withOpacity(0.03),
=======
                          color: Colors.white.withValues(alpha: 0.03),
>>>>>>> dev-ui2
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: _leaderboard.length <= 3 
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                              itemCount: _leaderboard.length - 3,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final user = _leaderboard[index + 3];
                                return _buildUserTile(user, index + 4);
                              },
                            ),
                      ),
                    ),
                  ],
                ),
                if (_myRank != null) _buildStickyMyRank(),
              ],
            ),
    );
  }

  Widget _buildTopThree() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_leaderboard.length > 1) _buildPodiumItem(_leaderboard[1], 2, 70),
          _buildPodiumItem(_leaderboard[0], 1, 90),
          if (_leaderboard.length > 2) _buildPodiumItem(_leaderboard[2], 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(dynamic user, int rank, double size) {
    final color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
<<<<<<< HEAD
                border: Border.all(color: color.withOpacity(0.5), width: 3),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 2),
=======
                border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
>>>>>>> dev-ui2
                ],
              ),
              child: CircleAvatar(
                radius: size / 2,
<<<<<<< HEAD
                backgroundColor: Colors.white.withOpacity(0.1),
=======
                backgroundColor: Colors.white.withValues(alpha: 0.1),
>>>>>>> dev-ui2
                child: Text(
                  (user['name'] ?? '?').substring(0, 1).toUpperCase(),
                  style: TextStyle(color: AppColors.textLight, fontSize: size * 0.4, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                rank.toString(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user['name'] ?? 'Anonymous',
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user['points']} pts',
          style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUserTile(dynamic user, int rank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank.toString(),
<<<<<<< HEAD
              style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontWeight: FontWeight.bold),
=======
              style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
>>>>>>> dev-ui2
            ),
          ),
          CircleAvatar(
            radius: 20,
<<<<<<< HEAD
            backgroundColor: Colors.white.withOpacity(0.05),
=======
            backgroundColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
            child: Text(
              (user['name'] ?? '?').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Anonymous',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Reputation: ${user['reputation']}',
<<<<<<< HEAD
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 12),
=======
                  style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5), fontSize: 12),
>>>>>>> dev-ui2
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['points']}',
                style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'POINTS',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyMyRank() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
<<<<<<< HEAD
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
=======
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
>>>>>>> dev-ui2
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
<<<<<<< HEAD
                color: AppColors.accentGreen.withOpacity(0.1),
=======
                color: AppColors.accentGreen.withValues(alpha: 0.1),
>>>>>>> dev-ui2
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'YOUR RANK: #${_myRank!['rank']}',
                style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_myRank!['points']} PTS',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Keep reporting to rank up!',
<<<<<<< HEAD
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 10),
=======
                  style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5), fontSize: 10),
>>>>>>> dev-ui2
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
<<<<<<< HEAD
          Icon(Icons.military_tech_rounded, color: AppColors.textLight.withOpacity(0.05), size: 80),
          const SizedBox(height: 16),
          Text(
            'The race is on!',
            style: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 16, fontWeight: FontWeight.bold),
=======
          Icon(Icons.military_tech_rounded, color: AppColors.textLight.withValues(alpha: 0.05), size: 80),
          const SizedBox(height: 16),
          Text(
            'The race is on!',
            style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.3), fontSize: 16, fontWeight: FontWeight.bold),
>>>>>>> dev-ui2
          ),
        ],
      ),
    );
  }
}
