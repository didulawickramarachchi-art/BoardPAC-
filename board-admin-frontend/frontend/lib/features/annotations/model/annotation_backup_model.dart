class AnnotationBackupModel {
  final int backupId;
  final int userId;
  final int annotationCount;
  final String backupJson;

  AnnotationBackupModel({
    required this.backupId,
    required this.userId,
    required this.annotationCount,
    required this.backupJson,
  });

  factory AnnotationBackupModel.fromJson(Map<String, dynamic> json) {
    return AnnotationBackupModel(
      backupId: json['backupId'],
      userId: json['userId'],
      annotationCount: json['annotationCount'] ?? 0,
      backupJson: json['backupJson'] ?? '',
    );
  }
}