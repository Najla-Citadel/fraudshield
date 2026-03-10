import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../screens/article_reader_screen.dart';
import '../constants/news_categories.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_empty_state.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<NewsItem> _items = [];
  NewsCategory? _selectedCategory;
  bool _isDescending = true; // For sorting

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _newsService.fetchLatest(
        limit: 40,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
          _sortItems();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _sortItems() {
    _items.sort((a, b) {
      if (a.published == null || b.published == null) return 0;
      return _isDescending
          ? b.published!.compareTo(a.published!)
          : a.published!.compareTo(b.published!);
    });
  }

  void _toggleSort() {
    setState(() {
      _isDescending = !_isDescending;
      _sortItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: AppLocalizations.of(context)!.newsTitle,
      actions: [
        IconButton(
          icon: Icon(_isDescending ? LucideIcons.chevronDown : LucideIcons.chevronUp,
              color: Colors.white),
          onPressed: _toggleSort,
          tooltip: 'Sort by date',
        ),
      ],
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? AppLoadingIndicator.center(
                    color: DesignTokens.colors.primary)
                : _error != null
                    ? _buildErrorState()
                    : _items.isEmpty
                        ? _buildEmptyState()
                        : _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xl, DesignTokens.spacing.md, DesignTokens.spacing.xl, 0),
      child: GlassSurface(
        borderRadius: DesignTokens.radii.lg,
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _loadNews(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search for scam terms...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            border: InputBorder.none,
            icon: Icon(LucideIcons.search, color: Colors.white.withOpacity(0.5), size: 18),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _loadNews();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xl, DesignTokens.spacing.sm, DesignTokens.spacing.xl, DesignTokens.spacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('All', null),
            ...allNewsCategories
                .map((cat) => _buildCategoryChip(cat.label, cat)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, NewsCategory? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _loadNews();
      },
      child: Container(
        margin: EdgeInsets.only(right: DesignTokens.spacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing.lg,
          vertical: DesignTokens.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.colors.primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
          border: Border.all(
            color: isSelected
                ? DesignTokens.colors.primary
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DesignTokens.colors.primary : Colors.white.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _loadNews,
      color: DesignTokens.colors.primary,
      backgroundColor: DesignTokens.colors.surfaceDark,
      child: ListView.separated(
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(height: 20),
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ArticleReaderScreen(title: item.title, url: item.url),
              ),
            ),
            child: GlassSurface(
              borderRadius: 24,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.image != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        item.image!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      ),
                    )
                  else
                    _buildPlaceholderImage(isTop: true),
                  Padding(
                    padding: EdgeInsets.all(DesignTokens.spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (item.excerpt != null) ...[
                          SizedBox(height: 8),
                          Text(
                            item.excerpt!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(LucideIcons.clock,
                                size: 14, color: Colors.white24),
                            SizedBox(width: 6),
                            Text(
                              item.published != null 
                                  ? _getTimeAgo(item.published!) 
                                  : AppLocalizations.of(context)!.newsLatestUpdate,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11),
                            ),
                            Spacer(),
                            Text(
                              AppLocalizations.of(context)!.newsReadMore,
                              style: TextStyle(
                                  color: DesignTokens.colors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Icon(LucideIcons.arrowRight, size: 14, color: DesignTokens.colors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPlaceholderImage({bool isTop = false}) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: isTop
            ? BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(DesignTokens.radii.xl),
      ),
      child: Icon(LucideIcons.newspaper, color: Colors.white24, size: 48),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: LucideIcons.searchX,
      title: 'No news found',
      description: 'We couldn\'t find any news articles matching your current filter.',
    );
  }

  Widget _buildErrorState() {
    return AppEmptyState(
      icon: LucideIcons.wifiOff,
      title: 'Failed to load news',
      description: _error ?? 'An unexpected error occurred while fetching news.',
      actionLabel: 'Try Again',
      onActionPressed: _loadNews,
    );
  }
}
