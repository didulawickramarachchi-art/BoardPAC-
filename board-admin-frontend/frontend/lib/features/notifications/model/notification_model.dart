class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final int? createdByUserId;
  final String createdByName;
  final String? createdByProfilePictureUrl;
  final List<NotificationReplyModel> replies;
  final Map<String, int> reactionCounts;
  final String? currentReaction;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.createdByUserId,
    required this.createdByName,
    this.createdByProfilePictureUrl,
    required this.replies,
    required this.reactionCounts,
    this.currentReaction,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _asInt(json['id'] ?? json['notificationId']),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      type: (json['type'] ?? json['notificationType'] ?? 'GENERAL').toString(),
      read: json['read'] == true || json['isRead'] == true,
      createdByUserId: _nullableInt(json['createdByUserId']),
      createdByName: (json['createdByName'] ?? 'System').toString(),
      createdByProfilePictureUrl: _nullableString(
        json['createdByProfilePictureUrl'],
      ),
      replies: _parseReplies(json['replies']),
      reactionCounts: _parseReactionCounts(json['reactionCounts']),
      currentReaction: _nullableString(json['currentReaction']),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['createdDate'] ?? '').toString(),
      ),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<NotificationReplyModel> _parseReplies(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(NotificationReplyModel.fromJson)
        .toList();
  }

  static Map<String, int> _parseReactionCounts(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, count) => MapEntry(
        key.toString(),
        count is int ? count : int.tryParse(count.toString()) ?? 0,
      ),
    );
  }
}

class NotificationReplyModel {
  final int id;
  final int userId;
  final String userName;
  final String? profilePictureUrl;
  final String message;
  final DateTime? createdAt;

  const NotificationReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.profilePictureUrl,
    required this.message,
    this.createdAt,
  });

  factory NotificationReplyModel.fromJson(Map<String, dynamic> json) {
    return NotificationReplyModel(
      id: NotificationModel._asInt(json['id']),
      userId: NotificationModel._asInt(json['userId']),
      userName: (json['userName'] ?? 'User').toString(),
      profilePictureUrl: NotificationModel._nullableString(
        json['profilePictureUrl'],
      ),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
