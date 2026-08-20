class UserRequest {
  final String firstName;
  final String lastName;
  final String? displayName;
  final String email;
  final String? officeEmail;
  final String? officeNumber;
  final String? mobileNumber;
  final String? jobTitle;
  final String role;
  final String boardType;
  final String accessProfile;
  final bool twoStepEnabled;

  UserRequest({
    required this.firstName,
    required this.lastName,
    this.displayName,
    required this.email,
    this.officeEmail,
    this.officeNumber,
    this.mobileNumber,
    this.jobTitle,
    required this.role,
    required this.boardType,
    required this.accessProfile,
    required this.twoStepEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'boardEmail': email,
      'officeEmail': officeEmail,
      'officeNumber': officeNumber,
      'mobileNumber': mobileNumber,
      'jobTitle': jobTitle,
      'role': role,
      'twoStepEnabled': twoStepEnabled,
      'boardType': boardType,
      'accessProfile': accessProfile,
    };
  }
}
