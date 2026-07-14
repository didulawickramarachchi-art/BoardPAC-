class CommentModel {
  final int id;
  final String createdByUsername;
  final String commentText;
  final bool annotated;
  final DateTime? createdAt;
  final int reactionCount;
  final bool reactedByCurrentUser;
  final String? currentReaction;
  final Map<String, int> reactionCounts;

  CommentModel({
    required this.id,
    required this.createdByUsername,
    required this.commentText,
    required this.annotated,
    this.createdAt,
    required this.reactionCount,
    required this.reactedByCurrentUser,
    this.currentReaction,
    required this.reactionCounts,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      createdByUsername: json['createdByUsername'] ?? '',
      commentText: json['commentText'] ?? '',
      annotated: json['annotated'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      reactedByCurrentUser: json['reactedByCurrentUser'] ?? false,
      currentReaction: json['currentReaction'],
      reactionCounts: (json['reactionCounts'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );
  }
}
