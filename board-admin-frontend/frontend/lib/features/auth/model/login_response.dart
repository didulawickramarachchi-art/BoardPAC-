class LoginResponse {
  final String? token;
  final String? refreshToken;
  final int? userId;
  final String? username;
  final String? role;
  final String? status;
  final String? message;
  final String? deviceStatus;
  final bool requiresTwoFactor;

  LoginResponse({
    this.token,
    this.refreshToken,
    this.userId,
    this.username,
    this.role,
    this.status,
    this.message,
    this.deviceStatus,
    required this.requiresTwoFactor,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      userId: json['userId'],
      username: json['username'],
      role: json['role'] ?? json['userRole'] ?? json['assignedRole'],
      status:
          json['status'] ??
          json['userStatus'] ??
          json['accountStatus'] ??
          (json['user'] is Map ? json['user']['status'] : null),
      message: json['message'],
      deviceStatus:
          json['deviceStatus'] ??
          json['deviceApprovalStatus'] ??
          (json['device'] is Map ? json['device']['status'] : null),
      requiresTwoFactor: json['requiresTwoFactor'] ?? false,
    );
  }

  bool get isDeactivated {
    final normalizedStatus = status?.trim().toUpperCase();
    return normalizedStatus == 'DEACTIVATED' || normalizedStatus == 'INACTIVE';
  }

  bool get requiresDeviceApproval {
    final normalized = deviceStatus?.trim().toUpperCase();
    return normalized == 'PENDING' ||
        normalized == 'REQUESTED' ||
        normalized == 'AWAITING_APPROVAL';
  }
}
