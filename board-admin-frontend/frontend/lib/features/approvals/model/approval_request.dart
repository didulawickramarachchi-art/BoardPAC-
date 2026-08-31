class ApprovalRequest {
  final int paperId;
  final String approvalStatus;
  final String? approvalComment;

  ApprovalRequest({
    required this.paperId,
    required this.approvalStatus,
    this.approvalComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'approvalStatus': approvalStatus,
      'approvalComment': approvalComment,
    };
  }
}
