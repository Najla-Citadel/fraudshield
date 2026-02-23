import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/scam_card.dart';
import '../widgets/community_map_card.dart';
import '../screens/scam_reporting_screen.dart';
import '../screens/report_details_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _reports = [];
  bool _isLoading = true;
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
    if (mounted) setState(() => _isLoading = true);

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
      // Backend unavailable — fall back to demo data so the UI is never blank
      debugPrint('[CommunityFeed] Error fetching feed: $e');
      debugPrint('[CommunityFeed] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _reports = [
            {
              'id': '1',
              'category': 'E-Wallet Phishing',
              'type': 'Phone',
              'description': 'Received an SMS claiming my TNG eWallet account was suspended. Link asked for PIN.',
              'target': '+6012-345 6789',
              'status': 'VERIFIED',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
              'user': 'User42xx',
              'location': 'Petaling Jaya, Selangor',
              'reporterTrust': {'score': 85},
              '_count': {'verifications': 12},
            },
            {
              'id': '2',
              'category': 'Investment Scam',
              'type': 'Message',
              'description': 'Telegram group promising 200% returns in 3 hours. Admin asked for deposit to "dummy" account.',
              'target': 'https://invest-fast.xy',
              'status': 'PENDING',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 14)).toIso8601String(),
              'user': 'User99xx',
              'location': 'Kuala Lumpur',
              'reporterTrust': {'score': 45},
              '_count': {'verifications': 8},
            },
            {
              'id': '3',
              'category': 'Courier Impersonation',
              'type': 'Phone',
              'description': 'Caller claimed to be from J&T stating I have an illegal parcel. Asked for bank details.',
              'target': '+6019-888 7777',
              'status': 'VERIFIED',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
              'user': 'User01xx',
              'location': 'Johor Bahru, Johor',
              'reporterTrust': {'score': 92},
              '_count': {'verifications': 5},
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121), // AppColors.deepNavy
      appBar: AppBar(
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        toolbarHeight: 90, // Sufficient height for two lines of text
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFeed,
        color: AppColors.accentGreen,
        backgroundColor: const Color(0xFF1E293B),
        child: _buildLiveFeed(),
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


  Widget _buildLiveFeed() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGreen));
    }

    if (_reports.isEmpty) {
      return Center(
        child: Text(
          'No reports yet. Be the first!',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      itemCount: _reports.length + 1,
      itemBuilder: (context, index) {
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
    );
  }
}
