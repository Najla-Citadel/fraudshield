import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/scam_card.dart';
import '../widgets/scam_map_view.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/search_filter_modal.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isMapMode = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  
  // Advanced filter state
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _minVerifications = 0;
  String _sortBy = 'newest';

  final List<String> _categories = [
    'All',
    'Investment Scam',
    'Phishing Scam',
    'Job Scam',
    'Love Scam',
    'Fake Giveaway / Promo Scam',
  ];
  
  bool get _hasActiveFilters =>
      _dateFrom != null ||
      _dateTo != null ||
      _minVerifications > 0 ||
      _sortBy != 'newest';

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _fetchFeed();
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterModal(
        initialDateFrom: _dateFrom,
        initialDateTo: _dateTo,
        initialMinVerifications: _minVerifications,
        initialSortBy: _sortBy,
        onApplyFilters: (dateFrom, dateTo, minVerifications, sortBy) {
          setState(() {
            _dateFrom = dateFrom;
            _dateTo = dateTo;
            _minVerifications = minVerifications;
            _sortBy = sortBy;
          });
          _fetchFeed();
        },
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    final isInitialLoad = _reports.isEmpty;

    if (isInitialLoad) {
      setState(() => _isLoading = true);
    }

    try {
      // Use search API if query or filters are present, otherwise use public feed
      if (_searchQuery.isNotEmpty || _hasActiveFilters) {
        final searchResult = await ApiService.instance.searchReports(
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          category: _selectedCategory != 'All' ? _selectedCategory : null,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          minVerifications: _minVerifications > 0 ? _minVerifications : null,
          sortBy: _sortBy,
        );
        final reports = searchResult['results'] as List;
        if (mounted) {
          setState(() {
            _reports = reports;
            _isLoading = false;
          });
        }
      } else {
        final reports = await ApiService.instance.getPublicFeed();
        if (mounted) {
          setState(() {
            _reports = reports;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching feed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _selectedCategory == 'All'
        ? _reports
        : _reports.where((r) => r['category'] == _selectedCategory).toList();

    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: _fetchFeed,
        child: AdaptiveScaffold(
          title: 'Community Scam Feed',
          actions: [
            // Filter button with badge
            IconButton(
              icon: Badge(
                isLabelVisible: _hasActiveFilters,
                label: const Text('•'),
                child: const Icon(Icons.filter_list),
              ),
              onPressed: _showFilterModal,
              tooltip: 'Filters',
            ),
            IconButton(
              icon: Icon(_isMapMode ? Icons.list : Icons.map_outlined),
              onPressed: () => setState(() => _isMapMode = !_isMapMode),
              tooltip: _isMapMode ? 'Show List' : 'Show Map',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchFeed,
            ),
          ],
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search scams by phone, URL, description...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Category Chips
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                        selectedColor: Colors.red,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredReports.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No reports in this category. Stay safe!')),
              )
            else if (_isMapMode)
              SliverFillRemaining(
                child: ScamMapView(
                  reports: filteredReports,
                  onRefresh: _fetchFeed,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: ScamCard(
                              report: filteredReports[index],
                              onVerify: _fetchFeed,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredReports.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
