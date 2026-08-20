class ApprovalModel {
  final int id;
  final int userId;
  final String username;
  final String approvalStatus;
  final String? approvalComment;

  ApprovalModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.approvalStatus,
    this.approvalComment,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'] ?? '',
      approvalStatus: json['approvalStatus'] ?? '',
      approvalComment: json['approvalComment'],
    );
  }
}
