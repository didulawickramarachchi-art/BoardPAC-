class NewsPost {
  final int id;
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final List<NewsComment> comments;
  final Map<String, int> reactions;
  final String? currentReaction;
  const NewsPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.imageUrl,
    this.imageUrls = const [],
    required this.createdAt,
    required this.comments,
    required this.reactions,
    this.currentReaction,
  });
  factory NewsPost.fromJson(Map<String, dynamic> j) => NewsPost(
    id: (j['id'] as num).toInt(),
    title: j['title'] ?? '',
    content: j['content'] ?? '',
    author: j['createdByName'] ?? 'Board Secretary',
    imageUrl: _images(j).isEmpty ? null : _images(j).first,
    imageUrls: _images(j),
    createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    comments: (j['comments'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NewsComment.fromJson)
        .toList(),
    reactions: (j['reactionCounts'] as Map? ?? const {}).map(
      (k, v) => MapEntry('$k', (v as num).toInt()),
    ),
    currentReaction: j['currentReaction']?.toString(),
  );

  static List<String> _images(Map<String, dynamic> json) {
    final multiple = (json['imageUrls'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (multiple.isNotEmpty) return multiple;
    final legacy = json['imageUrl']?.toString().trim() ?? '';
    return legacy.isEmpty ? const [] : [legacy];
  }
}

class NewsComment {
  final int id;
  final String author;
  final String message;
  final DateTime? createdAt;
  const NewsComment({
    required this.id,
    required this.author,
    required this.message,
    this.createdAt,
  });
  factory NewsComment.fromJson(Map<String, dynamic> j) => NewsComment(
    id: (j['id'] as num).toInt(),
    author: j['userName'] ?? 'User',
    message: j['message'] ?? '',
    createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
  );
}
