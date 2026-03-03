// lib/constants/news_categories.dart

class NewsCategory {
  final String label;
  final String keywords;

  const NewsCategory({
    required this.label,
    required this.keywords,
  });
}

const List<NewsCategory> allNewsCategories = [
  NewsCategory(
    label: 'Investment Scam',
    keywords: 'investment scam',
  ),
  NewsCategory(
    label: 'Phishing Scam',
    keywords: 'phishing scam OR email scam',
  ),
  NewsCategory(
    label: 'Job Scam',
    keywords: 'job scam OR hiring scam',
  ),
  NewsCategory(
    label: 'Love Scam',
    keywords: 'love scam OR romance scam',
  ),
  NewsCategory(
    label: 'Shopping Scam',
    keywords: 'shopping scam OR ecommerce scam',
  ),
  NewsCategory(
    label: 'Bank Fraud',
    keywords: 'bank fraud OR credit card scam',
  ),
  NewsCategory(
    label: 'Others',
    keywords: 'fraud OR scam',
  ),
];

const String defaultNewsQuery = 'malaysia scam OR fraud OR phishing';
