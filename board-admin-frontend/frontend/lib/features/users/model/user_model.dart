class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? displayName;
  final String boardEmail;
  final String? mobileNumber;
  final String? jobTitle;
  final String? role;
  final bool? twoStepEnabled;
  final String? status;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.displayName,
    required this.boardEmail,
    this.mobileNumber,
    this.jobTitle,
    this.role,
    this.twoStepEnabled,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      displayName: json['displayName'],
      boardEmail: json['boardEmail'] ?? '',
      mobileNumber: json['mobileNumber'],
      jobTitle: json['jobTitle'],
      role: json['role'] ?? json['userRole'],
      twoStepEnabled: json['twoStepEnabled'],
      status: json['status'],
    );
  }
}
