class CategoryModel {
  final int id;
  final String name;
  final String displayName;
  final int? displayOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      displayOrder: json['displayOrder'],
    );
  }
}