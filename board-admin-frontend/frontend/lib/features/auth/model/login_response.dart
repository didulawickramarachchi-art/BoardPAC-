class LoginResponse {
  final String? token;
  final String? refreshToken;
  final int? userId;
  final String? username;
  final String? role;
  final String? message;
  final bool requiresTwoFactor;

  LoginResponse({
    this.token,
    this.refreshToken,
    this.userId,
    this.username,
    this.role,
    this.message,
    required this.requiresTwoFactor,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      userId: json['userId'],
      username: json['username'],
      role: json['role'] ??
          json['userRole'] ??
          json['boardType'] ??
          json['assignedRole'],
      message: json['message'],
      requiresTwoFactor: json['requiresTwoFactor'] ?? false,
    );
  }
}
