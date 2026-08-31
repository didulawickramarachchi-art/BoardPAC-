class FavoriteModel {
  final String favoriteType;
  final int targetId;
  final String title;
  final String subtitle;
  final DateTime? createdAt;

  const FavoriteModel({
    required this.favoriteType,
    required this.targetId,
    required this.title,
    required this.subtitle,
    this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    favoriteType: json['favoriteType']?.toString() ?? '',
    targetId: (json['targetId'] as num).toInt(),
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}
