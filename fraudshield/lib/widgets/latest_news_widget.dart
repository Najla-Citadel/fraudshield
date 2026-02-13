// lib/widgets/latest_news_widget.dart
import 'package:flutter/material.dart';

import '../screens/article_reader_screen.dart';
import '../models/news_item.dart' as model;
import '../services/news_service.dart' as news_service;

class LatestNewsWidget extends StatefulWidget {
  const LatestNewsWidget({super.key, this.limit = 3});
  final int limit;

  @override
  State<LatestNewsWidget> createState() => _LatestNewsWidgetState();
}

class _LatestNewsWidgetState extends State<LatestNewsWidget> {
  final news_service.NewsService _newsService = news_service.NewsService();

  bool _loading = true;
  String? _error;
  List<model.NewsItem> _items = [];
  String _placeholderForIndex(int index) {
    const placeholders = [
      'assets/images/news_placeholder_1.png',
      'assets/images/news_placeholder_2.png',
      'assets/images/news_placeholder_3.png',
      'assets/images/news_placeholder_4.png',
    ];

    return placeholders[index % placeholders.length];
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  // ================= LOAD NEWS =================
  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _newsService.fetchLatest(limit: widget.limit);
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const containerHeight = 240.0; // Increased height to prevent overflow

    if (_loading) {
      return SizedBox(
        height: containerHeight,
        child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Unable to load insights: $_error',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            TextButton(onPressed: _loadNews, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text('No recent threat insights.', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
            TextButton(onPressed: _loadNews, child: const Text('Refresh')),
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

          return GestureDetector(
            onTap: () => _openArticle(item),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark Card
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: SizedBox(
                      height: 120, // Increased image height slightly
                      width: double.infinity,
                      child: Image.asset(
                        _placeholderForIndex(index),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // TITLE
                  Expanded( // Use Expanded to take remaining space
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('SCAM ALERT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 3, // Allow more lines
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
