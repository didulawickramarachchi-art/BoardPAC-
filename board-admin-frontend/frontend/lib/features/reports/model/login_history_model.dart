class LoginHistoryModel {
  final int id;
  final String username;
  final String? ipAddress;
  final String? deviceInfo;
  final String status;
  final String loginTime;

  LoginHistoryModel({
    required this.id,
    required this.username,
    this.ipAddress,
    this.deviceInfo,
    required this.status,
    required this.loginTime,
  });

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(
      id: json['id'],
      username: json['username'] ?? '',
      ipAddress: json['ipAddress'],
      deviceInfo: json['deviceInfo'],
      status: json['status'] ?? '',
      loginTime: json['loginTime'] ?? '',
    );
  }
}
