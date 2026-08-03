class DeviceModel {
  final int id;
  final String deviceId;
  final String? deviceInfo;
  final String? boardPacVersion;
  final String? osVersion;
  final String? description;
  final String? status;
  final String? username;

  DeviceModel({
    required this.id,
    required this.deviceId,
    this.deviceInfo,
    this.boardPacVersion,
    this.osVersion,
    this.description,
    this.status,
    this.username,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      deviceId: json['deviceId'] ?? '',
      deviceInfo: json['deviceInfo'],
      boardPacVersion: json['boardPacVersion'],
      osVersion: json['osVersion'],
      description: json['description'],
      status: json['status'],
      username: json['username'],
    );
  }

  String get normalizedStatus => status?.trim().toUpperCase() ?? 'UNKNOWN';

  bool get isPending =>
      normalizedStatus == 'PENDING' ||
      normalizedStatus == 'REQUESTED' ||
      normalizedStatus == 'AWAITING_APPROVAL';

  bool get isApproved =>
      normalizedStatus == 'APPROVED' || normalizedStatus == 'ACTIVE';

  bool get isDeactivated =>
      normalizedStatus == 'DEACTIVATED' || normalizedStatus == 'INACTIVE';

  bool get isWiped => normalizedStatus == 'WIPED';
}
