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
    const containerHeight = 150.0;

    if (_loading) {
      return SizedBox(
        height: containerHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'News error: $_error',
                style: const TextStyle(color: Colors.red),
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
            const Expanded(child: Text('No recent scam news found.')),
            TextButton(onPressed: _loadNews, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Latest Scam News',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: containerHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _items[index];

              return GestureDetector(
                onTap: () => _openArticle(item),
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: SizedBox(
                          height: 96,
                          width: double.infinity,
                          child: Image.asset(
                            _placeholderForIndex(index),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // TITLE
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
