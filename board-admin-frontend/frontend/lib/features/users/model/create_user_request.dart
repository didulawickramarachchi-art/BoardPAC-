class CreateUserRequest {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String boardEmail;
  final String role;

  const CreateUserRequest({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.boardEmail,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'boardEmail': boardEmail,
        'role': role,
      };
}
