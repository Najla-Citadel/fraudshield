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
  Future<List<model.NewsItem>> fetchLatest({int limit = 3, List<NewsCategory>? categories}) async {
    String query = defaultNewsQuery;
    
    if (categories != null && categories.isNotEmpty) {
      // Build a query: (cat1 OR cat2 OR cat3) malaysia
      final terms = categories.map((c) => '(${c.keywords})').join(' OR ');
      query = '($terms) malaysia';
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

      final title = titleNode?.text.trim();
      final link = linkNode?.text.trim();
      final excerpt = descNode?.text.trim();

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
        published: null,
      ));
    }

    return results;
  }

  static String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  static void clearCache() {}
}
