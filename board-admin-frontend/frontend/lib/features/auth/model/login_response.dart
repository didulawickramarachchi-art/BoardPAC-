class LoginResponse {
  final String? token;
  final String? refreshToken;
  final String? username;
  final String? message;
  final bool requiresTwoFactor;

  LoginResponse({
    this.token,
    this.refreshToken,
    this.username,
    this.message,
    required this.requiresTwoFactor,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      username: json['username'],
      message: json['message'],
      requiresTwoFactor: json['requiresTwoFactor'] ?? false,
    );
  }
}
