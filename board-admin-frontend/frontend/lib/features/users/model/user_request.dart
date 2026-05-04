class UserRequest {
  final String firstName;
  final String lastName;
  final String? displayName;
  final String boardEmail;
  final String? officeEmail;
  final String? officeNumber;
  final String? mobileNumber;
  final String? jobTitle;
  final String? boardType;
  final bool twoStepEnabled;

  UserRequest({
    required this.firstName,
    required this.lastName,
    this.displayName,
    required this.boardEmail,
    this.officeEmail,
    this.officeNumber,
    this.mobileNumber,
    this.jobTitle,
    this.boardType,
    required this.twoStepEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'boardEmail': boardEmail,
      'officeEmail': officeEmail,
      'officeNumber': officeNumber,
      'mobileNumber': mobileNumber,
      'jobTitle': jobTitle,
      'boardType': boardType,
      'twoStepEnabled': twoStepEnabled,
    };
  }
}