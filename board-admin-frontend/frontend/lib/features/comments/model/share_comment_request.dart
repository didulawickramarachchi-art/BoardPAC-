class ShareCommentRequest {
  final int commentId;
  final int sharedByUserId;
  final int sharedToUserId;

  ShareCommentRequest({
    required this.commentId,
    required this.sharedByUserId,
    required this.sharedToUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'sharedByUserId': sharedByUserId,
      'sharedToUserId': sharedToUserId,
    };
  }
}