class AgendaItemRequest {
  final int meetingId;
  final int? sectionId;
  final String itemType;
  final String title;
  final String? numberLabel;
  final int? displayOrder;
  final String? description;
  final String? mediaPath;

  AgendaItemRequest({
    required this.meetingId,
    this.sectionId,
    required this.itemType,
    required this.title,
    this.numberLabel,
    this.displayOrder,
    this.description,
    this.mediaPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'sectionId': sectionId,
      'itemType': itemType,
      'title': title,
      'numberLabel': numberLabel,
      'displayOrder': displayOrder,
      'description': description,
      'mediaPath': mediaPath,
    };
  }
}
