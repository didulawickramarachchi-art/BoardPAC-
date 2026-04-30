class Verify2FARequest {
  final String username;
  final String code;

  Verify2FARequest({required this.username, required this.code});

  Map<String, dynamic> toJson() {
    return {'username': username, 'code': code};
  }
}
