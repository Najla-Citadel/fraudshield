import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/api_service.dart';
import '../design_system/tokens/design_tokens.dart';
import '../widgets/scam_card.dart';
import '../widgets/community_map_card.dart';
import '../screens/scam_report_entry_screen.dart';
import '../screens/report_details_screen.dart';
import '../widgets/skeleton_card.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../widgets/error_state.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/socket_service.dart';

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

    // Listen for real-time new report notifications
    SocketService.instance.onNewPublicReport((data) {
      if (mounted && _selectedCategory == null && !_isSearchVisible) {
        // Auto-refresh only if on 'All' and not searching
        _fetchFeed(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabExtended && mounted) setState(() => _isFabExtended = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabExtended && mounted) setState(() => _isFabExtended = true);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
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
      backgroundColor: DesignTokens.colors.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF0A0F1F), // Deep Navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Main Content
          RefreshIndicator(
            onRefresh: () => _fetchFeed(reset: true),
            color: DesignTokens.colors.accentGreen,
            backgroundColor: Color(0xFF1E293B),
            child: AnimationLimiter(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: _buildFilters()),
                  _buildFeedList(),
                  if (_isFetchingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing.xl),
                        child: Center(
                            child: AppLoadingIndicator(size: 20)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor:
          Colors.transparent, // Update to transparent over gradient
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Feed',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -0.5),
                  ),
                  Text(
                    'Live scam reports near you',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        setState(() => _isSearchVisible = !_isSearchVisible),
                    icon: Icon(
                        _isSearchVisible ? LucideIcons.x : LucideIcons.search,
                        color: Colors.white),
                  ),
                  _buildNearMeToggle(),
                ],
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.sm),
        decoration: BoxDecoration(
          color: _isNearMe
              ? DesignTokens.colors.accentGreen.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
          border: Border.all(
            color: _isNearMe
                ? DesignTokens.colors.accentGreen
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 16,
              color: _isNearMe ? DesignTokens.colors.accentGreen : Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              'Near Me',
              style: TextStyle(
                color: _isNearMe ? DesignTokens.colors.accentGreen : Colors.white,
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
        color: Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search scams...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(LucideIcons.search,
              size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x,
                      size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    _fetchFeed(reset: true);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final categoryName =
              isAll ? 'All' : _categories[index - 1]['name'] as String;
          final categoryIcon = isAll
              ? LucideIcons.functionSquare
              : _categories[index - 1]['icon'] as IconData;
          final isSelected = isAll
              ? _selectedCategory == null
              : _selectedCategory == categoryName;

          return Padding(
            padding: EdgeInsets.only(right: DesignTokens.spacing.sm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isAll ? null : categoryName;
                });
                _fetchFeed(reset: true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.colors.accentGreen
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.colors.accentGreen
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcon,
                      size: 14,
                      color: isSelected ? Colors.black87 : Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      categoryName,
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedList() {
    if (_hasError && _reports.isEmpty) {
      return SliverFillRemaining(
          child: ErrorState(onRetry: () => _fetchFeed(reset: true)));
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
              Icon(LucideIcons.shieldAlert,
                  size: 64, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('No reports found',
                  style: TextStyle(
                      color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            Widget childWidget;
            if (index == 0) {
              childWidget = CommunityMapCard(threatCount: _reports.length);
            } else {
              final report = _reports[index - 1];
              childWidget = ScamCard(
                report: report,
                onVerify: () => _fetchFeed(reset: true),
                onFlag: (targetId, type) => _showFlagSheet(context, targetId, type),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(report: report)),
                  );
                },
              );
            }
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: childWidget,
                ),
              ),
            );
          },
          childCount: _reports.length + 1,
        ),
      ),
    );
  }

  void _showFlagSheet(BuildContext context, String targetId, String type) {
    final reasons = [
      {'key': 'false_accusation', 'label': 'False accusation', 'icon': Icons.gavel_rounded},
      {'key': 'harassment', 'label': 'Harassment or bullying', 'icon': Icons.warning_amber_rounded},
      {'key': 'spam', 'label': 'Spam or duplicate', 'icon': Icons.content_copy_rounded},
      {'key': 'pii_exposed', 'label': 'Exposes personal info', 'icon': Icons.privacy_tip_rounded},
      {'key': 'inappropriate', 'label': 'Inappropriate content', 'icon': Icons.block_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: DesignTokens.spacing.lg),
              Text(
                'Report this content',
                style: TextStyle(
                  color: DesignTokens.colors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: DesignTokens.spacing.xs),
              Text(
                'Why are you reporting this?',
                style: TextStyle(
                  color: DesignTokens.colors.textLight.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: DesignTokens.spacing.lg),
              ...reasons.map((r) => ListTile(
                leading: Icon(r['icon'] as IconData, color: Colors.white.withValues(alpha: 0.7), size: 22),
                title: Text(
                  r['label'] as String,
                  style: TextStyle(color: DesignTokens.colors.textLight, fontSize: 15),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final result = await ApiService.instance.flagContent(
                      targetId: targetId,
                      type: type,
                      reason: r['key'] as String,
                    );
                    if (mounted) {
                      final autoHidden = result['autoHidden'] == true;
                      AppSnackBar.showSuccess(
                        context,
                        autoHidden
                            ? 'Content hidden pending moderator review'
                            : 'Report submitted. Our moderators will review it.',
                      );
                      if (autoHidden) _fetchFeed(reset: true);
                    }
                  } catch (e) {
                    if (mounted) {
                      AppSnackBar.showError(context, 'Failed to report: $e');
                    }
                  }
                },
              )),
              SizedBox(height: DesignTokens.spacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: EdgeInsets.only(bottom: 100),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScamReportEntryScreen()),
          );
        },
        backgroundColor: DesignTokens.colors.accentGreen,
        isExtended: _isFabExtended,
        icon: Icon(LucideIcons.plusCircle, color: Colors.black87),
        label: Text(
          'Report a Scam',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5),
        ),
      ),
    );
  }
}
