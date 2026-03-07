import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/components/app_skeleton.dart';
import '../design_system/components/app_button.dart';

import '../screens/article_reader_screen.dart';
import '../design_system/tokens/design_tokens.dart';
import '../models/news_item.dart' as model;
import '../services/news_service.dart' as news_service;
import '../constants/news_categories.dart';

class LatestNewsWidget extends StatefulWidget {
  const LatestNewsWidget({super.key, this.limit = 3});
  final int limit;

  @override
  State<LatestNewsWidget> createState() => LatestNewsWidgetState();
}

class LatestNewsWidgetState extends State<LatestNewsWidget> {
  final news_service.NewsService _newsService = news_service.NewsService();

  bool _loading = true;
  String? _error;
  List<model.NewsItem> _items = [];
  List<String> _selectedCategoryLabels = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadPreferences();
    await _loadNews();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCategoryLabels = prefs.getStringList('news_categories') ?? [];
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('news_categories', _selectedCategoryLabels);
  }

  String _placeholderForIndex(int index) {
    const placeholders = [
      'assets/images/news_placeholder_1.png',
      'assets/images/news_placeholder_2.png',
      'assets/images/news_placeholder_3.png',
      'assets/images/news_placeholder_4.png',
    ];
    return placeholders[index % placeholders.length];
  }

  // ================= LOAD NEWS =================
  Future<void> _loadNews() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final selectedCats = allNewsCategories
          .where((c) => _selectedCategoryLabels.contains(c.label))
          .toList();

      final list = await _newsService.fetchLatest(
        limit: widget.limit,
        categories: selectedCats.isEmpty ? null : selectedCats,
      );
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Public method to refresh externally if needed
  void refresh() => _loadNews();

  // ================= OPEN ARTICLE (IN APP) =================
  void _openArticle(model.NewsItem item) {
    if (item.url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleReaderScreen(
          title: item.title,
          url: item.url,
        ),
      ),
    );
  }

  void showCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.colors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(DesignTokens.spacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customize Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select categories to follow local scam trends.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: allNewsCategories.map((cat) {
                      final isSelected = _selectedCategoryLabels.contains(cat.label);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              _selectedCategoryLabels.remove(cat.label);
                            } else {
                              _selectedCategoryLabels.add(cat.label);
                            }
                          });
                          _savePreferences();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? DesignTokens.colors.accentGreen.withOpacity(0.1) 
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                            border: Border.all(
                              color: isSelected ? DesignTokens.colors.accentGreen : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) 
                                Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(LucideIcons.check, color: Colors.blueAccent, size: 14),
                                ),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: isSelected ? DesignTokens.colors.accentGreen : Colors.white,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  AppButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadNews();
                    },
                    label: 'Update Feed',
                    variant: AppButtonVariant.primary,
                    width: double.infinity,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const containerHeight = 240.0;

    if (_loading) {
      return SizedBox(
        height: containerHeight,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xs),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(width: 16),
          itemBuilder: (_, __) => AppSkeleton.card(
            width: 280,
            height: containerHeight,
            borderRadius: 20,
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Unable to load insights: $_error',
                    style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.7)),
                  ),
                ),
                TextButton(onPressed: _loadNews, child: Text('Retry')),
              ],
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: showCustomization,
              icon: Icon(LucideIcons.sliders, size: 16),
              label: Text('Change Categories'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('No recent threat insights for selected categories.', style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.5)))),
                TextButton(onPressed: _loadNews, child: Text('Refresh')),
              ],
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: showCustomization,
              icon: Icon(LucideIcons.sliders, size: 16),
              label: Text('Change Categories'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: containerHeight,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xs),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            onTap: () => _openArticle(item),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: Image.asset(
                        _placeholderForIndex(index),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.sm, vertical: DesignTokens.spacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                            ),
                            child: Text('SCAM ALERT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
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
}
