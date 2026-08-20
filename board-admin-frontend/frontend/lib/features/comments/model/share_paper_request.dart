class SharePaperRequest {
  final int paperId;
  final int sharedByUserId;
  final int sharedToUserId;

  SharePaperRequest({
    required this.paperId,
    required this.sharedByUserId,
    required this.sharedToUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'sharedByUserId': sharedByUserId,
      'sharedToUserId': sharedToUserId,
    };
  }
}
