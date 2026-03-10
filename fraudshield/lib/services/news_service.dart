// lib/services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// model alias (your existing model file)
import '../models/news_item.dart' as model;
import '../constants/news_categories.dart';

class NewsService {
  /// Fetch latest articles from Google News RSS
  /// [categories] is an optional list of NewsCategory to filter news.
  /// [searchQuery] is an optional string to search specific terms.
  Future<List<model.NewsItem>> fetchLatest({
    int limit = 20, 
    List<NewsCategory>? categories,
    String? searchQuery,
  }) async {
    String query = '';
    
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = '(${searchQuery.trim()}) malaysia';
    } else if (categories != null && categories.isNotEmpty) {
      // Build a query: (cat1 OR cat2 OR cat3) malaysia
      final terms = categories.map((c) => '(${c.keywords})').join(' OR ');
      query = '($terms) malaysia';
    } else {
      query = defaultNewsQuery;
    }

    final encodedQuery = Uri.encodeComponent(query);
    final rssUrl = 'https://news.google.com/rss/search?q=$encodedQuery&hl=en-MY&gl=MY&ceid=MY:en';
    final uri = Uri.parse(rssUrl);

    final resp = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36',
      'Accept': 'application/rss+xml, application/xml, text/xml, */*',
    });

    if (resp.statusCode != 200) {
      throw Exception('Failed to load news (status: ${resp.statusCode})');
    }

    // parse XML
    final doc = xml.XmlDocument.parse(utf8.decode(resp.bodyBytes));
    final items = doc.findAllElements('item');

    final results = <model.NewsItem>[];

    for (final it in items) {
      if (results.length >= limit) break;

      final titleNode = it.getElement('title');
      final linkNode = it.getElement('link');
      final descNode = it.getElement('description');
      final dateNode = it.getElement('pubDate');

      final title = titleNode?.text.trim();
      final link = linkNode?.text.trim();
      final excerpt = descNode?.text.trim();
      final dateStr = dateNode?.text.trim();
      
      DateTime? published;
      if (dateStr != null) {
        published = _parseRfc822Date(dateStr);
      }

      if (title == null || link == null) continue;

      String? image;
      final thumbs = it.findAllElements('thumbnail');
      if (thumbs.isNotEmpty) {
        final t = thumbs.first;
        final urlAttr = t.getAttribute('url') ?? t.getAttribute('src');
        if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
      }

      if (image == null) {
        final en = it.getElement('enclosure');
        final urlAttr = en?.getAttribute('url');
        if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
      }

      if (image == null) {
        final mediaContents = it.findAllElements('content');
        if (mediaContents.isNotEmpty) {
          final urlAttr = mediaContents.first.getAttribute('url');
          if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
        }
      }

      if (image == null && excerpt != null && excerpt.isNotEmpty) {
        final imgMatch = RegExp("url\\([\"']?(.*?)[\"']?\\)", caseSensitive: false)
            .firstMatch(excerpt);
        if (imgMatch != null) {
          final src = imgMatch.group(1);
          if (src != null && src.isNotEmpty) image = src.trim();
        }
      }

      if (image != null && image.isNotEmpty && image.startsWith('//')) {
        image = 'https:$image';
      }

      results.add(model.NewsItem(
        title: title,
        url: link,
        excerpt: _stripHtml(excerpt ?? ''),
        image: image,
        published: published,
      ));
    }

    return results;
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

  static DateTime? _parseRfc822Date(String dateString) {
    try {
      // RFC 822 format: "Tue, 10 Mar 2026 05:30:00 GMT"
      // Split and extract the relevant parts manually for reliability
      final parts = dateString.split(' ');
      if (parts.length < 4) return DateTime.tryParse(dateString);

      final day = int.tryParse(parts[1]);
      final monthStr = parts[2];
      final year = int.tryParse(parts[3]);

      if (day == null || year == null) return DateTime.tryParse(dateString);

      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };

      final month = months[monthStr];
      if (month == null) return DateTime.tryParse(dateString);

      // Extract time: HH:mm:ss
      int hour = 0;
      int minute = 0;
      int second = 0;
      if (parts.length >= 5) {
        final timeParts = parts[4].split(':');
        if (timeParts.length >= 2) {
          hour = int.tryParse(timeParts[0]) ?? 0;
          minute = int.tryParse(timeParts[1]) ?? 0;
          if (timeParts.length >= 3) {
            second = int.tryParse(timeParts[2]) ?? 0;
          }
        }
      }

      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (_) {
      return DateTime.tryParse(dateString);
    }
  }

  static void clearCache() {}
}
