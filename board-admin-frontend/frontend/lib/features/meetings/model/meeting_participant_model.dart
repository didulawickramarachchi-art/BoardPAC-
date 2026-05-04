class MeetingParticipantModel {
  final int id;
  final int userId;
  final String username;
  final String participantStatus;
  final String? statusReason;
  final int? displaySequence;

  MeetingParticipantModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.participantStatus,
    this.statusReason,
    this.displaySequence,
  });

  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) {
    return MeetingParticipantModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'] ?? '',
      participantStatus: json['participantStatus'] ?? '',
      statusReason: json['statusReason'],
      displaySequence: json['displaySequence'],
    );
  }
}
