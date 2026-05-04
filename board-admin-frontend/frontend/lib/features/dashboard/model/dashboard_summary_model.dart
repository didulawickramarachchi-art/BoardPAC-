class DashboardSummaryModel {
  final int totalMeetings;
  final int totalCirculars;
  final int pendingApprovals;
  final int unreadPapers;
  final int sharedComments;
  final int sharedDocuments;

  DashboardSummaryModel({
    required this.totalMeetings,
    required this.totalCirculars,
    required this.pendingApprovals,
    required this.unreadPapers,
    required this.sharedComments,
    required this.sharedDocuments,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalMeetings: json['totalMeetings'] ?? 0,
      totalCirculars: json['totalCirculars'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
      unreadPapers: json['unreadPapers'] ?? 0,
      sharedComments: json['sharedComments'] ?? 0,
      sharedDocuments: json['sharedDocuments'] ?? 0,
    );
  }
}