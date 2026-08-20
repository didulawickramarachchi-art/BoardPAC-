class CreateUserRequest {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String boardEmail;
  final String role;
  final String boardType;
  final String accessProfile;

  const CreateUserRequest({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.boardEmail,
    required this.role,
    required this.boardType,
    required this.accessProfile,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'boardEmail': boardEmail,
      'role': role,
      'boardType': boardType,
      'accessProfile': accessProfile,
    };
  }
}
