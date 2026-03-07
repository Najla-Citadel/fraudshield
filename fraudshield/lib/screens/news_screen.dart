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
  bool _isLoading = true;
  String? _error;
  List<NewsItem> _items = [];
  NewsCategory? _selectedCategory;

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
        limit: 20,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
      );
      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: AppLocalizations.of(context)!.newsTitle,
      body: Column(
        children: [
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
    return Padding(
      padding: EdgeInsets.only(right: DesignTokens.spacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedCategory = category);
            _loadNews();
          }
        },
        selectedColor: DesignTokens.colors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white.withOpacity(0.05),
        elevation: 0,
        pressElevation: 0,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radii.lg)),
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
                              AppLocalizations.of(context)!.newsLatestUpdate,
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
