class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? displayName;
  final String email;
  final String? mobileNumber;
  final String? jobTitle;
  final String? profilePictureUrl;
  final String? role;
  final String? boardType;
  final String? accessProfile;
  final bool? twoStepEnabled;
  final String? status;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.displayName,
    required this.email,
    this.mobileNumber,
    this.jobTitle,
    this.profilePictureUrl,
    this.role,
    this.boardType,
    this.accessProfile,
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
      email: json['email'] ?? json['boardEmail'] ?? '',
      mobileNumber: json['mobileNumber'],
      jobTitle: json['jobTitle'],
      profilePictureUrl:
          json['profilePictureUrl'] ??
          json['profilePictureURL'] ??
          json['profile_picture_url'] ??
          json['profilePicture'],
      role: json['role'] ?? json['userRole'],
      boardType: json['boardType'],
      accessProfile: json['accessProfile'],
      twoStepEnabled: json['twoStepEnabled'],
      status: json['status'],
    );
  }

  /// User lifecycle values are supplied by the backend as strings. Keep the
  /// checks here so every screen handles casing and the common INACTIVE alias
  /// consistently.
  bool get isDeactivated {
    final normalizedStatus = status?.trim().toUpperCase();
    return normalizedStatus == 'DEACTIVATED' || normalizedStatus == 'INACTIVE';
  }

  bool get isActive => status?.trim().toUpperCase() == 'ACTIVE';
}
