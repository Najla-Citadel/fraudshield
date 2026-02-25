class BadgeModel {
  final String id;
  final String key;
  final String name;
  final String description;
  final String icon;
  final String tier;
  final String trigger;
  final int? threshold;
  final bool isEarned;

  BadgeModel({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.trigger,
    this.threshold,
    this.isEarned = false,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      tier: json['tier'] ?? 'bronze',
      trigger: json['trigger'] ?? 'custom',
      threshold: json['threshold'],
      isEarned: json['isEarned'] ?? false,
    );
  }
}
