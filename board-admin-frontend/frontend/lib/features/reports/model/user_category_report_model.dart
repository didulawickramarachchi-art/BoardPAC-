class UserCategoryReportModel {
  final int userId;
  final String username;
  final String categoryName;
  final String subcategoryName;
  final String assignedRole;

  UserCategoryReportModel({
    required this.userId,
    required this.username,
    required this.categoryName,
    required this.subcategoryName,
    required this.assignedRole,
  });

  factory UserCategoryReportModel.fromJson(Map<String, dynamic> json) {
    return UserCategoryReportModel(
      userId: json['userId'],
      username: json['username'] ?? '',
      categoryName: json['categoryName'] ?? '',
      subcategoryName: json['subcategoryName'] ?? '',
      assignedRole: json['assignedRole'] ?? '',
    );
  }
}
