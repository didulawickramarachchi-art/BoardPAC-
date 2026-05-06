class DashboardSummaryModel {
  final int totalUsers;
  final int totalMeetings;
  final int totalCirculars;
  final int pendingApprovals;
  final int unreadPapers;
  final int sharedComments;
  final int sharedDocuments;

  final String? upcomingMeetingTitle;
  final String? upcomingMeetingDateTime;
  final String? upcomingMeetingLocation;
  final String? upcomingMeetingDaysText;

  DashboardSummaryModel({
    required this.totalUsers,
    required this.totalMeetings,
    required this.totalCirculars,
    required this.pendingApprovals,
    required this.unreadPapers,
    required this.sharedComments,
    required this.sharedDocuments,
    this.upcomingMeetingTitle,
    this.upcomingMeetingDateTime,
    this.upcomingMeetingLocation,
    this.upcomingMeetingDaysText,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalMeetings: json['totalMeetings'] ?? 0,
      totalCirculars: json['totalCirculars'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
      unreadPapers: json['unreadPapers'] ?? 0,
      sharedComments: json['sharedComments'] ?? 0,
      sharedDocuments: json['sharedDocuments'] ?? 0,

      upcomingMeetingTitle: json['upcomingMeetingTitle'],
      upcomingMeetingDateTime: json['upcomingMeetingDateTime'],
      upcomingMeetingLocation: json['upcomingMeetingLocation'],
      upcomingMeetingDaysText: json['upcomingMeetingDaysText'],
    );
  }
}