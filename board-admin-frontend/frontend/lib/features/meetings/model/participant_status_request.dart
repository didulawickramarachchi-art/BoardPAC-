class ParticipantStatusRequest {
  final int meetingId;
  final int userId;
  final String participantStatus;
  final String? statusReason;

  ParticipantStatusRequest({
    required this.meetingId,
    required this.userId,
    required this.participantStatus,
    this.statusReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'userId': userId,
      'participantStatus': participantStatus,
      'statusReason': statusReason,
    };
  }
}
