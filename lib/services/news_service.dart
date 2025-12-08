// lib/services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/news_item.dart' as model;

/// Scrape FreeMalaysiaToday search results for "FRAUD".
/// Returns List<model.NewsItem> where fields are:
/// - title (String)
/// - link  (String)
/// - excerpt (String?)
/// - imageUrl (String?)
class NewsService {
  static const _base = 'https://www.freemalaysiatoday.com';

  Future<List<model.NewsItem>> fetchLatest({int limit = 3}) async {
    final searchUrl = 'https://www.freemalaysiatoday.com/search?term=FRAUD&category=all';

    final resp = await http.get(Uri.parse(searchUrl));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch news (status ${resp.statusCode})');
    }

    final doc = html_parser.parse(utf8.decode(resp.bodyBytes));

    // Collect candidate article elements using several selectors (site may change).
    final candidates = <Element>[];
    candidates.addAll(doc.querySelectorAll('article'));
    candidates.addAll(doc.querySelectorAll('.td_module_wrap'));
    candidates.addAll(doc.querySelectorAll('.article-entry'));
    candidates.addAll(doc.querySelectorAll('.post'));
    candidates.addAll(doc.querySelectorAll('.td-module')); // extra fallback

    // Deduplicate while preserving order
    final seen = <Element>{};
    final filtered = <Element>[];
    for (final el in candidates) {
      if (!seen.contains(el)) {
        seen.add(el);
        filtered.add(el);
      }
    }

    final items = <model.NewsItem>[];
    for (final el in filtered) {
      if (items.length >= limit) break;

      final title = _extractTitle(el);
      final url = _extractUrl(el);
      if (title == null || url == null) continue;

      final excerpt = _extractExcerpt(el);
      final image = _extractImageFromElement(el);

      items.add(model.NewsItem(
        title: title,
        link: _absoluteUrl(url),
        excerpt: excerpt,
        imageUrl: image != null ? _absoluteUrl(image) : null,
      ));
    }

    return items;
  }

  String? _extractTitle(Element el) {
    final t = el.querySelector('h3 a') ??
        el.querySelector('h2 a') ??
        el.querySelector('.entry-title a') ??
        el.querySelector('.td-module-title a') ??
        el.querySelector('a.title') ??
        el.querySelector('a');
    if (t == null) return null;
    return t.text.trim();
  }

  String? _extractUrl(Element el) {
    final a = el.querySelector('h3 a') ??
        el.querySelector('h2 a') ??
        el.querySelector('.entry-title a') ??
        el.querySelector('.td-module-title a') ??
        el.querySelector('a.title') ??
        el.querySelector('a');
    if (a == null) return null;
    final href = a.attributes['href'] ?? a.attributes['data-href'];
    if (href == null) return null;
    return href.trim();
  }

  String? _extractExcerpt(Element el) {
    final p = el.querySelector('p') ?? el.querySelector('.excerpt') ?? el.querySelector('.td-excerpt');
    if (p != null) {
      final t = p.text.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  String? _extractImageFromElement(Element el) {
    // 1) direct <img>
    final img = el.querySelector('img');
    if (img != null) {
      final src = img.attributes['data-src'] ??
          img.attributes['src'] ??
          img.attributes['data-lazy-src'] ??
          img.attributes['data-original'];
      if (src != null && src.isNotEmpty) return src.trim();
    }

    // 2) try style background-image (url("...") / url('...') / url(...))
    final bg = el.querySelector('[style*="background-image"], [style*="background"]');
    if (bg != null) {
      final style = bg.attributes['style'] ?? '';
      // raw string pattern — safe and readable
      final reg = RegExp("url\\([\"']?(.*?)[\"']?\\)");
      final match = reg.firstMatch(style);
      if (match != null) {
        final captured = match.group(1);
        if (captured != null && captured.isNotEmpty) return captured.trim();
      }
    }

    // 3) figure img fallback
    final figImg = el.querySelector('figure img');
    if (figImg != null) {
      final src = figImg.attributes['src'] ?? figImg.attributes['data-src'];
      if (src != null && src.isNotEmpty) return src.trim();
    }

    // 4) meta og:image (rare for snippet but safe to attempt)
    final metaImg = el.querySelector('meta[property="og:image"]');
    if (metaImg != null) {
      final src = metaImg.attributes['content'];
      if (src != null && src.isNotEmpty) return src.trim();
    }

    return null;
  }

  String _absoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '$_base$url';
    return '$_base/$url';
  }
}
