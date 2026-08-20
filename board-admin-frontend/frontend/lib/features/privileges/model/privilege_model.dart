class PrivilegeModel {
  final int id;
  final int userId;
  final String username;
  final int subcategoryId;
  final String subcategoryName;
  final String assignedRole;
  final int? displaySequence;

  PrivilegeModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.assignedRole,
    this.displaySequence,
  });

  factory PrivilegeModel.fromJson(Map<String, dynamic> json) {
    return PrivilegeModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'] ?? '',
      subcategoryId: json['subcategoryId'],
      subcategoryName: json['subcategoryName'] ?? '',
      assignedRole: json['assignedRole'] ?? '',
      displaySequence: json['displaySequence'],
    );
  }
}
