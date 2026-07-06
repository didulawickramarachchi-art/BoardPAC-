class AccessValidationModel {
  final int userId;
  final String username;
  final String requestedChannel;
  final bool allowed;
  final String reason;

  AccessValidationModel({
    required this.userId,
    required this.username,
    required this.requestedChannel,
    required this.allowed,
    required this.reason,
  });

  factory AccessValidationModel.fromJson(Map<String, dynamic> json) {
    return AccessValidationModel(
      userId: json['userId'],
      username: json['username'] ?? '',
      requestedChannel: json['requestedChannel'] ?? '',
      allowed: json['allowed'] ?? false,
      reason: json['reason'] ?? '',
    );
  }
}