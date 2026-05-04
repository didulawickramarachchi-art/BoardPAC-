class AccessValidationModel {
  final int userId;
  final String username;
  final String? boardType;
  final String requestedChannel;
  final bool allowed;
  final String reason;

  AccessValidationModel({
    required this.userId,
    required this.username,
    this.boardType,
    required this.requestedChannel,
    required this.allowed,
    required this.reason,
  });

  factory AccessValidationModel.fromJson(Map<String, dynamic> json) {
    return AccessValidationModel(
      userId: json['userId'],
      username: json['username'] ?? '',
      boardType: json['boardType'],
      requestedChannel: json['requestedChannel'] ?? '',
      allowed: json['allowed'] ?? false,
      reason: json['reason'] ?? '',
    );
  }
}