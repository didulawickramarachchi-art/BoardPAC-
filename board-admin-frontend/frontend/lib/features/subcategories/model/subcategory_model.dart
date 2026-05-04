class SubcategoryModel {
  final int id;
  final String name;
  final String displayName;
  final int? displayOrder;
  final int categoryId;
  final String categoryName;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayOrder,
    required this.categoryId,
    required this.categoryName,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      displayOrder: json['displayOrder'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? '',
    );
  }
}