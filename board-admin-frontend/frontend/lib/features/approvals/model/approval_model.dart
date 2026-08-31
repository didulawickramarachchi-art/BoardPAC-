class ApprovalModel {
  final int id;
  final int userId;
  final String username;
  final String approvalStatus;
  final String? approvalComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool ownedByCurrentUser;

  ApprovalModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.approvalStatus,
    this.approvalComment,
    this.createdAt,
    this.updatedAt,
    required this.ownedByCurrentUser,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'] ?? '',
      approvalStatus: json['approvalStatus'] ?? '',
      approvalComment: json['approvalComment'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      ownedByCurrentUser: json['ownedByCurrentUser'] ?? false,
    );
  }
}
