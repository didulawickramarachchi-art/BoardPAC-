class CategoryRequest {
  final String name;
  final String displayName;
  final int? displayOrder;
  final String? imageUrl;

  const CategoryRequest({
    required this.name,
    required this.displayName,
    this.displayOrder,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'displayOrder': displayOrder,
      'imageUrl': imageUrl,
    };
  }
}
