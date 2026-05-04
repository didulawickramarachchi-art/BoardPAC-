class LicenseUtilizationModel {
  final int totalUsers;
  final int activeUsers;
  final int deactivatedUsers;
  final int lockedUsers;
  final int deletedUsers;

  LicenseUtilizationModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.deactivatedUsers,
    required this.lockedUsers,
    required this.deletedUsers,
  });

  factory LicenseUtilizationModel.fromJson(Map<String, dynamic> json) {
    return LicenseUtilizationModel(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      deactivatedUsers: json['deactivatedUsers'] ?? 0,
      lockedUsers: json['lockedUsers'] ?? 0,
      deletedUsers: json['deletedUsers'] ?? 0,
    );
  }
}
