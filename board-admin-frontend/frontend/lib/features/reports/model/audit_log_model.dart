class AuditLogModel {
  final int id;
  final String level;
  final String moduleName;
  final String actionName;
  final String username;
  final String? parameters;
  final String? device;
  final String actionTime;

  AuditLogModel({
    required this.id,
    required this.level,
    required this.moduleName,
    required this.actionName,
    required this.username,
    this.parameters,
    this.device,
    required this.actionTime,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      level: json['level'] ?? '',
      moduleName: json['moduleName'] ?? '',
      actionName: json['actionName'] ?? '',
      username: json['username'] ?? '',
      parameters: json['parameters'],
      device: json['device'],
      actionTime: json['actionTime'] ?? '',
    );
  }
}
