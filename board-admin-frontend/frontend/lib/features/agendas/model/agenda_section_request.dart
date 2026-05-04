class AgendaSectionRequest {
  final int meetingId;
  final String title;
  final String? numberLabel;
  final int? displayOrder;

  AgendaSectionRequest({
    required this.meetingId,
    required this.title,
    this.numberLabel,
    this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'title': title,
      'numberLabel': numberLabel,
      'displayOrder': displayOrder,
    };
  }
}
