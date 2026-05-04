class MeetingRequest {
  final String title;
  final String type;
  final String meetingDateTime;
  final String? targetDateTime;
  final String? location;
  final String? description;
  final int categoryId;
  final int subcategoryId;
  final int createdByUserId;

  MeetingRequest({
    required this.title,
    required this.type,
    required this.meetingDateTime,
    this.targetDateTime,
    this.location,
    this.description,
    required this.categoryId,
    required this.subcategoryId,
    required this.createdByUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'meetingDateTime': meetingDateTime,
      'targetDateTime': targetDateTime,
      'location': location,
      'description': description,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'createdByUserId': createdByUserId,
    };
  }
}
