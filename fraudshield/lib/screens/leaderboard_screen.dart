import 'package:flutter/material.dart';
import '../design_system/components/app_back_button.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/tokens/design_tokens.dart';
import '../services/api_service.dart';

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
      backgroundColor: DesignTokens.colors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'GLOBAL LEADERBOARD',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const AppBackButton(color: Colors.white),
      ),
      body: _isLoading
          ? AppLoadingIndicator.center()
          : Stack(
              children: [
                Column(
                  children: [
                    _buildTopThree(),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(top: DesignTokens.spacing.xxl),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: _leaderboard.length <= 3 
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xxl, DesignTokens.spacing.xxl, DesignTokens.spacing.xxl, 120),
                              itemCount: _leaderboard.length - 3,
                              separatorBuilder: (context, index) => SizedBox(height: 12),
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
    if (_leaderboard.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl, vertical: DesignTokens.spacing.md),
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
    final color = rank == 1 ? Color(0xFFFFD700) : (rank == 2 ? Color(0xFFC0C0C0) : Color(0xFFCD7F32));
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: DesignTokens.spacing.md),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 3),
                boxShadow: DesignTokens.shadows.md,
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Text(
                  (user['name'] ?? '?').substring(0, 1).toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacing.xs),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                rank.toString(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          user['name'] ?? 'Anonymous',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user['points']} pts',
          style: TextStyle(color: DesignTokens.colors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildUserTile(dynamic user, int rank) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank.toString(),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.05),
            child: Text(
              (user['name'] ?? '?').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Anonymous',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Reputation: ${user['reputation']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['points']}',
                style: TextStyle(color: DesignTokens.colors.accentGreen, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
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
        margin: EdgeInsets.all(DesignTokens.spacing.xxl),
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
          boxShadow: DesignTokens.shadows.md,
          border: Border.all(color: DesignTokens.colors.accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.sm),
              decoration: BoxDecoration(
                color: DesignTokens.colors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: Text(
                'YOUR RANK: #${_myRank!['rank']}',
                style: TextStyle(color: DesignTokens.colors.accentGreen, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_myRank!['points']} PTS',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Keep reporting to rank up!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
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
          Icon(Icons.military_tech_rounded, color: Colors.white.withOpacity(0.05), size: 80),
          SizedBox(height: 16),
          Text(
            'The race is on!',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
