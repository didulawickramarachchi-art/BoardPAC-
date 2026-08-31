class CommentModel {
  final int id;
  final int createdByUserId;
  final String createdByUsername;
  final String? createdByProfilePictureUrl;
  final String commentText;
  final bool annotated;
  final String visibility;
  final int? pageNumber;
  final bool ownedByCurrentUser;
  final List<int> selectedUserIds;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int reactionCount;
  final bool reactedByCurrentUser;
  final String? currentReaction;
  final Map<String, int> reactionCounts;
  final List<CommentReplyModel> replies;

  CommentModel({
    required this.id,
    required this.createdByUserId,
    required this.createdByUsername,
    this.createdByProfilePictureUrl,
    required this.commentText,
    required this.annotated,
    required this.visibility,
    this.pageNumber,
    required this.ownedByCurrentUser,
    required this.selectedUserIds,
    this.updatedAt,
    this.createdAt,
    required this.reactionCount,
    required this.reactedByCurrentUser,
    this.currentReaction,
    required this.reactionCounts,
    required this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      createdByUserId: (json['createdByUserId'] as num?)?.toInt() ?? 0,
      createdByUsername: json['createdByUsername'] ?? '',
      createdByProfilePictureUrl: json['createdByProfilePictureUrl'],
      commentText: json['commentText'] ?? '',
      annotated: json['annotated'] ?? false,
      visibility: json['visibility'] ?? 'ALL_PARTICIPANTS',
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      ownedByCurrentUser: json['ownedByCurrentUser'] ?? false,
      selectedUserIds: (json['selectedUserIds'] as List? ?? const []).map((e) => (e as num).toInt()).toList(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      reactedByCurrentUser: json['reactedByCurrentUser'] ?? false,
      currentReaction: json['currentReaction'],
      reactionCounts: (json['reactionCounts'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      replies: (json['replies'] as List? ?? const [])
          .map((item) => CommentReplyModel.fromJson(item))
          .toList(),
    );
  }
}

class CommentReplyModel {
  final int id;
  final int createdByUserId;
  final String createdByUsername;
  final String? createdByProfilePictureUrl;
  final String message;
  final DateTime? createdAt;

  const CommentReplyModel({
    required this.id,
    required this.createdByUserId,
    required this.createdByUsername,
    this.createdByProfilePictureUrl,
    required this.message,
    this.createdAt,
  });

  factory CommentReplyModel.fromJson(Map<String, dynamic> json) {
    return CommentReplyModel(
      id: (json['id'] as num).toInt(),
      createdByUserId: (json['createdByUserId'] as num?)?.toInt() ?? 0,
      createdByUsername: json['createdByUsername'] ?? '',
      createdByProfilePictureUrl: json['createdByProfilePictureUrl'],
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
