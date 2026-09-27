class MeetingRequest {
  final String title;
  final String type;
  final String meetingDateTime;
  final String? targetDateTime;
  final String? location;
  final String? description;
  final String? imageUrl;
  final int categoryId;
  final int subcategoryId;

  MeetingRequest({
    required this.title,
    required this.type,
    required this.meetingDateTime,
    this.targetDateTime,
    this.location,
    this.description,
    this.imageUrl,
    required this.categoryId,
    required this.subcategoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'meetingDateTime': meetingDateTime,
      'targetDateTime': targetDateTime,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
    };
  }
}
