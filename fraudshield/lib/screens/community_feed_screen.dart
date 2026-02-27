import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/scam_card.dart';
import '../widgets/community_map_card.dart';
import '../screens/scam_reporting_screen.dart';
import '../screens/report_details_screen.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  String? _selectedCategory;
  bool _isNearMe = false;
  bool _isSearchVisible = false;
  bool _isFabExtended = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Job', 'icon': LucideIcons.briefcase},
    {'name': 'Investment', 'icon': LucideIcons.trendingUp},
    {'name': 'Phishing', 'icon': LucideIcons.link2},
    {'name': 'E-commerce', 'icon': LucideIcons.shoppingBag},
    {'name': 'Impersonation', 'icon': LucideIcons.users},
    {'name': 'Loan', 'icon': LucideIcons.banknote},
    {'name': 'Others', 'icon': LucideIcons.moreHorizontal}
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchFeed(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabExtended && mounted) setState(() => _isFabExtended = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabExtended && mounted) setState(() => _isFabExtended = true);
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore && !_isLoading) {
        _fetchFeed();
      }
    }
  }

  Future<void> _fetchFeed({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _reports.clear();
          _offset = 0;
          _hasMore = true;
          _hasError = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isFetchingMore = true);
      }
    }

    try {
      // Mock coordinates if "Near Me" is enabled
      double? lat, lng, radius;
      if (_isNearMe) {
        lat = 3.1390; // Kuala Lumpur
        lng = 101.6869;
        radius = 50;
      }

      final response = await ApiService.instance.getPublicFeed(
        category: _selectedCategory,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        lat: lat,
        lng: lng,
        radius: radius,
        limit: _limit,
        offset: _offset,
      );

      final List<dynamic> newReports = response['results'] ?? [];
      
      if (mounted) {
        setState(() {
          _reports.addAll(newReports);
          _isLoading = false;
          _isFetchingMore = false;
          _hasMore = response['hasMore'] ?? false;
          _offset += _limit;
        });
      }
    } catch (e) {
      debugPrint('[CommunityFeed] Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: RefreshIndicator(
        onRefresh: () => _fetchFeed(reset: true),
        color: AppColors.accentGreen,
        backgroundColor: const Color(0xFF1E293B),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildFilters()),
            _buildFeedList(),
            if (_isFetchingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.deepNavy,
      floating: true,
      snap: true,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: _isSearchVisible ? 120 : 90,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Feed',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  Text(
                    'Live scam reports near you',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isSearchVisible = !_isSearchVisible),
                    icon: Icon(_isSearchVisible ? LucideIcons.x : LucideIcons.search, color: Colors.white70),
                  ),
                  _buildNearMeToggle(),
                ],
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            const SizedBox(height: 12),
            _buildSearchBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildNearMeToggle() {
    return InkWell(
      onTap: () {
        setState(() => _isNearMe = !_isNearMe);
        _fetchFeed(reset: true);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isNearMe ? AppColors.accentGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isNearMe ? AppColors.accentGreen : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 16,
              color: _isNearMe ? AppColors.accentGreen : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              'Near Me',
              style: TextStyle(
                color: _isNearMe ? AppColors.accentGreen : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search scams...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.white38),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(LucideIcons.x, size: 16, color: Colors.white38),
                onPressed: () {
                  _searchController.clear();
                  _fetchFeed(reset: true);
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onSubmitted: (val) {
          _fetchFeed(reset: true);
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final categoryName = isAll ? 'All' : _categories[index - 1]['name'] as String;
          final categoryIcon = isAll ? LucideIcons.functionSquare : _categories[index - 1]['icon'] as IconData;
          final isSelected = isAll ? _selectedCategory == null : _selectedCategory == categoryName;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                categoryIcon,
                size: 14,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              label: Text(categoryName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = isAll ? null : categoryName;
                });
                _fetchFeed(reset: true);
              },
              backgroundColor: const Color(0xFF1E293B),
              selectedColor: AppColors.accentGreen,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedList() {
    if (_hasError && _reports.isEmpty) {
      return SliverFillRemaining(child: ErrorState(onRetry: () => _fetchFeed(reset: true)));
    }

    if (_isLoading && _reports.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const SkeletonCard(),
          childCount: 5,
        ),
      );
    }

    if (_reports.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shieldAlert, size: 64, color: Colors.white10),
              const SizedBox(height: 16),
              const Text('No reports found', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return CommunityMapCard(threatCount: _reports.length);
            }
            final report = _reports[index - 1];
            return ScamCard(
              report: report,
              onVerify: () => _fetchFeed(reset: true),
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

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScamReportingScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB), // Sleek blue
        isExtended: _isFabExtended,
        icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
        label: const Text(
          'Report a Scam',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
