class MeetingModel {
  final int id;
  final String title;
  final String type;
  final String status;
  final String meetingDateTime;
  final String? targetDateTime;
  final String? location;
  final String? description;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;

  MeetingModel({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.meetingDateTime,
    this.targetDateTime,
    this.location,
    this.description,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      meetingDateTime: json['meetingDateTime'] ?? '',
      targetDateTime: json['targetDateTime'],
      location: json['location'],
      description: json['description'],
      categoryName: json['categoryName'],
      subcategoryId: (json['subcategoryId'] as num?)?.toInt(),
      subcategoryName: json['subcategoryName'],
    );
  }
}
