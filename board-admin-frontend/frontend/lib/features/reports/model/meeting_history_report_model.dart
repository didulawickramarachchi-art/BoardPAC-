class MeetingHistoryReportModel {
  final int id;
  final String title;
  final String status;
  final String meetingDateTime;
  final String? location;
  final String? description;
  final int categoryId;
  final String categoryName;
  final int subcategoryId;
  final String subcategoryName;
  final List<MeetingHistoryPaperModel> papers;

  const MeetingHistoryReportModel({
    required this.id,
    required this.title,
    required this.status,
    required this.meetingDateTime,
    this.location,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.papers,
  });

  factory MeetingHistoryReportModel.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryReportModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      meetingDateTime: json['meetingDateTime'] ?? '',
      location: json['location'],
      description: json['description'],
      categoryId: (json['categoryId'] as num).toInt(),
      categoryName: json['categoryName'] ?? '',
      subcategoryId: (json['subcategoryId'] as num).toInt(),
      subcategoryName: json['subcategoryName'] ?? '',
      papers: (json['papers'] as List? ?? const [])
          .map((item) => MeetingHistoryPaperModel.fromJson(item))
          .toList(),
    );
  }
}

class MeetingHistoryPaperModel {
  final int id;
  final String title;
  final String paperType;
  final String? referenceNumber;
  final int? versionNumber;

  const MeetingHistoryPaperModel({
    required this.id,
    required this.title,
    required this.paperType,
    this.referenceNumber,
    this.versionNumber,
  });

  factory MeetingHistoryPaperModel.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryPaperModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] ?? '',
      paperType: json['paperType'] ?? '',
      referenceNumber: json['referenceNumber'],
      versionNumber: (json['versionNumber'] as num?)?.toInt(),
    );
  }
}
