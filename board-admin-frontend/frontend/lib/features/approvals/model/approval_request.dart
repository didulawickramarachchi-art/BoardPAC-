class ApprovalRequest {
  final int paperId;
  final int userId;
  final String approvalStatus;
  final String? approvalComment;

  ApprovalRequest({
    required this.paperId,
    required this.userId,
    required this.approvalStatus,
    this.approvalComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'userId': userId,
      'approvalStatus': approvalStatus,
      'approvalComment': approvalComment,
    };
  }
}
