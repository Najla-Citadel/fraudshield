// lib/services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// model alias (your existing model file)
import '../models/news_item.dart' as model;

class NewsService {
  /// Google News RSS search tuned for Malaysia + scam/fraud/phishing
  /// - returns up to [limit] items
  /// - example query: malaysia scam OR fraud OR phishing
  static const _googleRss =
      'https://news.google.com/rss/search?q=malaysia+scam+OR+fraud+OR+phishing&hl=en-MY&gl=MY&ceid=MY:en';

  /// Fetch latest articles from Google News RSS
  Future<List<model.NewsItem>> fetchLatest({int limit = 3}) async {
    final uri = Uri.parse(_googleRss);

    final resp = await http.get(uri, headers: {
      // polite UA; Google accepts normal clients
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

      // 1) try media:thumbnail (often provided by Google RSS)
      String? image;
      // find any element named 'thumbnail' (namespace may vary)
      final thumbs = it.findAllElements('thumbnail');
      if (thumbs.isNotEmpty) {
        final t = thumbs.first;
        final urlAttr = t.getAttribute('url') ?? t.getAttribute('src');
        if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
      }

      // 2) try enclosure element (<enclosure url="...">)
      if (image == null) {
        final en = it.getElement('enclosure');
        final urlAttr = en?.getAttribute('url');
        if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
      }

      // 3) try media:content
      if (image == null) {
        final mediaContents = it.findAllElements('content');
        if (mediaContents.isNotEmpty) {
          final urlAttr = mediaContents.first.getAttribute('url');
          if (urlAttr != null && urlAttr.isNotEmpty) image = urlAttr.trim();
        }
      }

      // 4) fallback: attempt to extract first <img src="..."> inside description HTML
      if (image == null && excerpt != null && excerpt.isNotEmpty) {
        final imgMatch = RegExp("url\\([\"']?(.*?)[\"']?\\)", caseSensitive: false)
            .firstMatch(excerpt);
        if (imgMatch != null) {
          final src = imgMatch.group(1);
          if (src != null && src.isNotEmpty) image = src.trim();
        }
      }

      // normalize relative urls (Google should supply absolute URLs but be safe)
      if (image != null && image.isNotEmpty && image.startsWith('//')) {
        image = 'https:$image';
      }

      results.add(model.NewsItem(
        title: title,
        url: link,
        excerpt: // prefer a cleaned short excerpt (strip html tags if present)
            _stripHtml(excerpt ?? ''),
        image: image,
        published: null,
      ));
    }

    return results;
  }

  // small helper to remove HTML tags from description excerpts
  static String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  // optional helper to clear any cache if you add caching
  static void clearCache() {}
}
