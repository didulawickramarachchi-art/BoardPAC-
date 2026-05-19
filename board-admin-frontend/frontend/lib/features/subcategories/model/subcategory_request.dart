class SubcategoryRequest {
  final String name;
  final String displayName;
  final int? displayOrder;
  final int categoryId;

  const SubcategoryRequest({
    required this.name,
    required this.displayName,
    this.displayOrder,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'displayOrder': displayOrder,
      'categoryId': categoryId,
    };
  }
}
