class CommentModel {
  final int id;
  final String createdByUsername;
  final String commentText;
  final bool annotated;

  CommentModel({
    required this.id,
    required this.createdByUsername,
    required this.commentText,
    required this.annotated,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      createdByUsername: json['createdByUsername'] ?? '',
      commentText: json['commentText'] ?? '',
      annotated: json['annotated'] ?? false,
    );
  }
}