class NotificationRequest {
  final String title;
  final String message;
  final String type;
  final int? createdByUserId;
  final int? targetUserId;
  final int? relatedMeetingId;
  final int? relatedPaperId;
  final int? relatedCommentId;
  final int? relatedAttachmentId;
  final bool announcement;

  const NotificationRequest({
    required this.title,
    required this.message,
    required this.type,
    this.createdByUserId,
    this.targetUserId,
    this.relatedMeetingId,
    this.relatedPaperId,
    this.relatedCommentId,
    this.relatedAttachmentId,
    this.announcement = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'createdByUserId': createdByUserId,
      'targetUserId': targetUserId,
      'relatedMeetingId': relatedMeetingId,
      'relatedPaperId': relatedPaperId,
      'relatedCommentId': relatedCommentId,
      'relatedAttachmentId': relatedAttachmentId,
      'announcement': announcement,
    };
  }
}
