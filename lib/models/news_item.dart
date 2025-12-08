// lib/models/news_item.dart
class NewsItem {
  final String title;
  final String link;
  final String? excerpt;
  final String? imageUrl;
  final DateTime? publishedAt;

  NewsItem({
    required this.title,
    required this.link,
    this.excerpt,
    this.imageUrl,
    this.publishedAt,
  });

  factory NewsItem.fromMap(Map<String, dynamic> m) {
    return NewsItem(
      title: m['title']?.toString() ?? '',
      link: m['link']?.toString() ?? '',
      excerpt: m['excerpt']?.toString(),
      imageUrl: m['imageUrl']?.toString() ?? m['image']?.toString(),
      publishedAt: m['publishedAt'] != null ? DateTime.tryParse(m['publishedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'link': link,
        'excerpt': excerpt,
        'imageUrl': imageUrl,
        'publishedAt': publishedAt?.toIso8601String(),
      };
}
