class MeetingMinutesModel {
  final int id;
  final int meetingId;
  final int versionNumber;
  final String content;
  final String status;
  final String createdBy;
  final String? reviewedBy;
  final String? reviewComment;
  final DateTime? publishedAt;

  const MeetingMinutesModel({
    required this.id,
    required this.meetingId,
    required this.versionNumber,
    required this.content,
    required this.status,
    required this.createdBy,
    this.reviewedBy,
    this.reviewComment,
    this.publishedAt,
  });

  factory MeetingMinutesModel.fromJson(Map<String, dynamic> json) =>
      MeetingMinutesModel(
        id: (json['id'] as num).toInt(),
        meetingId: (json['meetingId'] as num).toInt(),
        versionNumber: (json['versionNumber'] as num).toInt(),
        content: json['content']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdBy: json['createdBy']?.toString() ?? '',
        reviewedBy: json['reviewedBy']?.toString(),
        reviewComment: json['reviewComment']?.toString(),
        publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      );
}
