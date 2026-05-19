class CategoryRequest {
  final String name;
  final String displayName;
  final int? displayOrder;

  const CategoryRequest({
    required this.name,
    required this.displayName,
    this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'displayOrder': displayOrder,
    };
  }
}
