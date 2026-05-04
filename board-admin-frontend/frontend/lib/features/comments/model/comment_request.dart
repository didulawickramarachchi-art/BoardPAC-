class CommentRequest {
  final int? meetingId;
  final int? paperId;
  final int createdByUserId;
  final String commentText;
  final bool annotated;

  CommentRequest({
    this.meetingId,
    this.paperId,
    required this.createdByUserId,
    required this.commentText,
    required this.annotated,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'paperId': paperId,
      'createdByUserId': createdByUserId,
      'commentText': commentText,
      'annotated': annotated,
    };
  }
}