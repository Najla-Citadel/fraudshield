import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/scam_card.dart';
import '../widgets/community_map_card.dart';
import '../screens/scam_reporting_screen.dart';
import '../screens/report_details_screen.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  // Tab controller for "Live Feed" vs "Top Reporters"
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeed() async {
    if (mounted) setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch live data from the backend
      debugPrint('[CommunityFeed] Fetching public feed...');
      final reports = await ApiService.instance.getPublicFeed();
      debugPrint('[CommunityFeed] Got ${reports.length} reports from API');
      if (reports.isNotEmpty) {
        debugPrint('[CommunityFeed] First report: ${reports[0]}');
      }
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[CommunityFeed] Error fetching feed: $e');
      debugPrint('[CommunityFeed] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121), // AppColors.deepNavy
      body: RefreshIndicator(
        onRefresh: _fetchFeed,
        color: AppColors.accentGreen,
        backgroundColor: const Color(0xFF1E293B),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Community Feed',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live scam reports from users near you',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0B1121),
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 90,
              floating: true,
              snap: true,
            ),
            _buildLiveFeedSliver(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScamReportingScreen()),
            );
          },
          backgroundColor: const Color(0xFF2563EB), // Bright Blue
          icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
          label: const Text(
            'Report a Scam',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeedSliver() {
    if (_hasError) {
      return SliverFillRemaining(
        child: ErrorState(onRetry: _fetchFeed),
      );
    }

    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.only(top: 10, bottom: 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const SkeletonCard(),
            childCount: 5,
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No reports yet. Be the first!',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _reports.length) {
              // Bottom Widget: Community Map Card
              return const CommunityMapCard();
            }
            final report = _reports[index];
            return ScamCard(
              report: report,
              onVerify: _fetchFeed,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: report)),
                );
              },
            );
          },
          childCount: _reports.length + 1,
        ),
      ),
    );
  }
}
