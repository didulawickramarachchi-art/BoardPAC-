class CommentRequest {
  final int? meetingId;
  final int? paperId;
  final String commentText;
  final bool annotated;
  final String visibility;
  final int? pageNumber;
  final List<int> selectedUserIds;

  CommentRequest({
    this.meetingId,
    this.paperId,
    required this.commentText,
    required this.annotated,
    this.visibility = 'ALL_PARTICIPANTS',
    this.pageNumber,
    this.selectedUserIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'paperId': paperId,
      'commentText': commentText,
      'annotated': annotated,
      'visibility': visibility,
      'pageNumber': pageNumber,
      'selectedUserIds': selectedUserIds,
    };
  }
}
