import '../models/news_item.dart' as model;

// lib/models/news_item.dart
class NewsItem {
  final String title;
  final String url;     // <-- canonical url field used by widget/service
  final String? excerpt;
  final String? image;  // <-- canonical image field used by widget/service
  final DateTime? published; // optional, if the service extracts it

  NewsItem({
    required this.title,
    required this.url,
    this.excerpt,
    this.image,
    this.published,
  });

  // helper factory (if you later want to construct from a map)
  factory NewsItem.fromMap(Map<String, dynamic> m) {
    return NewsItem(
      title: m['title'] as String? ?? '',
      url: m['url'] as String? ?? m['link'] as String? ?? '',
      excerpt: m['excerpt'] as String?,
      image: m['image'] as String? ?? m['imageUrl'] as String?,
      published: m['published'] != null ? DateTime.tryParse(m['published'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      if (excerpt != null) 'excerpt': excerpt,
      if (image != null) 'image': image,
      if (published != null) 'published': published!.toIso8601String(),
    };
  }
}
