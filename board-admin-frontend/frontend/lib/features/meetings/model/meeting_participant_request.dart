class MeetingParticipantRequest {
  final int meetingId;
  final int userId;
  final int? displaySequence;

  MeetingParticipantRequest({
    required this.meetingId,
    required this.userId,
    this.displaySequence,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'userId': userId,
      'displaySequence': displaySequence,
    };
  }
}
