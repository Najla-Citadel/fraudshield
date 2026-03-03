// lib/widgets/latest_news_widget.dart
import 'package:flutter/material.dart';
<<<<<<< HEAD

import '../screens/article_reader_screen.dart';
import '../models/news_item.dart' as model;
import '../services/news_service.dart' as news_service;
=======
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/article_reader_screen.dart';
import '../constants/colors.dart';
import '../models/news_item.dart' as model;
import '../services/news_service.dart' as news_service;
import '../constants/news_categories.dart';
>>>>>>> dev-ui2

class LatestNewsWidget extends StatefulWidget {
  const LatestNewsWidget({super.key, this.limit = 3});
  final int limit;

  @override
<<<<<<< HEAD
  State<LatestNewsWidget> createState() => _LatestNewsWidgetState();
}

class _LatestNewsWidgetState extends State<LatestNewsWidget> {
=======
  State<LatestNewsWidget> createState() => LatestNewsWidgetState();
}

class LatestNewsWidgetState extends State<LatestNewsWidget> {
>>>>>>> dev-ui2
  final news_service.NewsService _newsService = news_service.NewsService();

  bool _loading = true;
  String? _error;
  List<model.NewsItem> _items = [];
<<<<<<< HEAD
=======
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

>>>>>>> dev-ui2
  String _placeholderForIndex(int index) {
    const placeholders = [
      'assets/images/news_placeholder_1.png',
      'assets/images/news_placeholder_2.png',
      'assets/images/news_placeholder_3.png',
      'assets/images/news_placeholder_4.png',
    ];
<<<<<<< HEAD

    return placeholders[index % placeholders.length];
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  // ================= LOAD NEWS =================
  Future<void> _loadNews() async {
=======
    return placeholders[index % placeholders.length];
  }

  // ================= LOAD NEWS =================
  Future<void> _loadNews() async {
    if (!mounted) return;
>>>>>>> dev-ui2
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
<<<<<<< HEAD
      final list = await _newsService.fetchLatest(limit: widget.limit);
=======
      final selectedCats = allNewsCategories
          .where((c) => _selectedCategoryLabels.contains(c.label))
          .toList();

      final list = await _newsService.fetchLatest(
        limit: widget.limit,
        categories: selectedCats.isEmpty ? null : selectedCats,
      );
>>>>>>> dev-ui2
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

<<<<<<< HEAD
  // ================= OPEN ARTICLE (IN APP) =================
  void _openArticle(model.NewsItem item) {
    if (item.url.isEmpty) return;

=======
  // Public method to refresh externally if needed
  void refresh() => _loadNews();

  // ================= OPEN ARTICLE (IN APP) =================
  void _openArticle(model.NewsItem item) {
    if (item.url.isEmpty) return;
>>>>>>> dev-ui2
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

<<<<<<< HEAD
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const containerHeight = 240.0; // Increased height to prevent overflow
=======
  void showCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
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
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select categories to follow local scam trends.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.accentGreen.withValues(alpha: 0.1) 
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.accentGreen : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) 
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.check, color: Colors.blueAccent, size: 14),
                                ),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: isSelected ? AppColors.accentGreen : Colors.white,
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadNews();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Update Feed'),
                    ),
                  ),
                  const SizedBox(height: 20),
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
>>>>>>> dev-ui2

    if (_loading) {
      return SizedBox(
        height: containerHeight,
<<<<<<< HEAD
        child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
=======
        child: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
>>>>>>> dev-ui2
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
<<<<<<< HEAD
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Unable to load insights: $_error',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            TextButton(onPressed: _loadNews, child: const Text('Retry')),
=======
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Unable to load insights: $_error',
                    style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
                  ),
                ),
                TextButton(onPressed: _loadNews, child: const Text('Retry')),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: showCustomization,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Change Categories'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
>>>>>>> dev-ui2
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
<<<<<<< HEAD
        child: Row(
          children: [
            Expanded(child: Text('No recent threat insights.', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
            TextButton(onPressed: _loadNews, child: const Text('Refresh')),
=======
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('No recent threat insights for selected categories.', style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5)))),
                TextButton(onPressed: _loadNews, child: const Text('Refresh')),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: showCustomization,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Change Categories'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
>>>>>>> dev-ui2
          ],
        ),
      );
    }

    return SizedBox(
      height: containerHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = _items[index];
<<<<<<< HEAD

=======
>>>>>>> dev-ui2
          return GestureDetector(
            onTap: () => _openArticle(item),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
<<<<<<< HEAD
                color: const Color(0xFF1E293B), // Dark Card
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
=======
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< HEAD
                  // IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: SizedBox(
                      height: 120, // Increased image height slightly
=======
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 120,
>>>>>>> dev-ui2
                      width: double.infinity,
                      child: Image.asset(
                        _placeholderForIndex(index),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
<<<<<<< HEAD

                  // TITLE
                  Expanded( // Use Expanded to take remaining space
=======
                  Expanded(
>>>>>>> dev-ui2
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
<<<<<<< HEAD
                              color: Colors.red.withOpacity(0.2),
=======
                              color: Colors.red.withValues(alpha: 0.2),
>>>>>>> dev-ui2
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('SCAM ALERT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
<<<<<<< HEAD
                            maxLines: 3, // Allow more lines
=======
                            maxLines: 3,
>>>>>>> dev-ui2
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
