// lib/services/news_service.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class NewsItem {
  final String title;
  final String url;

  NewsItem({required this.title, required this.url});
}

class NewsService {
  // in-memory cache
  static List<NewsItem>? _cached;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetch latest fraud-related news from FreeMalaysiaToday search page.
  /// Returns up to [limit] items.
  static Future<List<NewsItem>> fetchFraudNews({int limit = 5}) async {
    // return cached if fresh
    if (_cached != null && _cacheTime != null && DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cached!;
    }

    final uri = Uri.parse('https://www.freemalaysiatoday.com/search?term=FRAUD&category=all');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('Failed to fetch news: ${resp.statusCode}');

    final doc = html_parser.parse(resp.body);

    // Strategy:
    // - Many WP-like sites render search results as article elements or list items with anchors.
    // - We'll try a few selectors to collect likely result anchors.
    final anchors = <Element>[];

    // 1) search for <article> with anchor
    final articles = doc.querySelectorAll('article');
    for (final a in articles) {
      final anchor = a.querySelector('a[href]');
      if (anchor != null) anchors.add(anchor);
      if (anchors.length >= limit) break;
    }

    // 2) fallback: common result containers (class names may vary)
    if (anchors.isEmpty) {
      // try common containers
      final candSelectors = [
        '.search-results a[href]',
        '.entry-title a[href]',
        '.post a[href]',
        '.listing a[href]',
        'a[href]'
      ];

      for (final sel in candSelectors) {
        final cand = doc.querySelectorAll(sel);
        for (final el in cand) {
          final href = el.attributes['href'] ?? '';
          final text = el.text.trim();
          if (href.isEmpty || text.isEmpty) continue;
          // heuristics: link likely to be an article
          if (href.contains('/202') || href.contains('/scam') || href.contains('/news') || text.length > 10) {
            anchors.add(el);
            if (anchors.length >= limit) break;
          }
        }
        if (anchors.length >= limit) break;
      }
    }

    // build list of unique items
    final seen = <String>{};
    final items = <NewsItem>[];
    for (final a in anchors) {
      final href = a.attributes['href'] ?? '';
      final title = a.text.trim();
      if (href.isEmpty || title.isEmpty) continue;
      // normalize URL
      final url = href.startsWith('http') ? href : 'https://www.freemalaysiatoday.com${href.startsWith('/') ? '' : '/'}$href';
      if (seen.add(url)) {
        items.add(NewsItem(title: title, url: url));
        if (items.length >= limit) break;
      }
    }

    // update cache
    _cached = items;
    _cacheTime = DateTime.now();

    return items;
  }

  /// Optionally call this to clear cache (e.g. on manual refresh)
  static void clearCache() {
    _cached = null;
    _cacheTime = null;
  }
}
