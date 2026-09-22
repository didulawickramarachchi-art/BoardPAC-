class PendingApprovalReportModel {
  final int paperId;
  final String paperTitle;
  final int userId;
  final String username;
  final String meetingTitle;
  final DateTime? submittedAt;
  final int approvalAgeDays;

  PendingApprovalReportModel({
    required this.paperId,
    required this.paperTitle,
    required this.userId,
    required this.username,
    required this.meetingTitle,
    this.submittedAt,
    this.approvalAgeDays = 0,
  });

  factory PendingApprovalReportModel.fromJson(Map<String, dynamic> json) {
    return PendingApprovalReportModel(
      paperId: json['paperId'],
      paperTitle: json['paperTitle'] ?? '',
      userId: json['userId'],
      username: json['username'] ?? '',
      meetingTitle: json['meetingTitle'] ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
      approvalAgeDays: (json['approvalAgeDays'] as num?)?.toInt() ?? 0,
    );
  }
}
