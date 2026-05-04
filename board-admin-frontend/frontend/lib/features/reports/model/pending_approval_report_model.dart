class PendingApprovalReportModel {
  final int paperId;
  final String paperTitle;
  final int userId;
  final String username;
  final String meetingTitle;

  PendingApprovalReportModel({
    required this.paperId,
    required this.paperTitle,
    required this.userId,
    required this.username,
    required this.meetingTitle,
  });

  factory PendingApprovalReportModel.fromJson(Map<String, dynamic> json) {
    return PendingApprovalReportModel(
      paperId: json['paperId'],
      paperTitle: json['paperTitle'] ?? '',
      userId: json['userId'],
      username: json['username'] ?? '',
      meetingTitle: json['meetingTitle'] ?? '',
    );
  }
}
