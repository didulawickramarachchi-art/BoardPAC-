class PrivateMeetingNoteModel {
  final int id;
  final int meetingId;
  final String noteText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrivateMeetingNoteModel({
    required this.id,
    required this.meetingId,
    required this.noteText,
    this.createdAt,
    this.updatedAt,
  });

  factory PrivateMeetingNoteModel.fromJson(Map<String, dynamic> json) =>
      PrivateMeetingNoteModel(
        id: (json['id'] as num).toInt(),
        meetingId: (json['meetingId'] as num).toInt(),
        noteText: json['noteText']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );
}
