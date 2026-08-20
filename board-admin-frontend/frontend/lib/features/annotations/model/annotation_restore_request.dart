class AnnotationRestoreRequest {
  final int backupId;
  final int userId;

  AnnotationRestoreRequest({required this.backupId, required this.userId});

  Map<String, dynamic> toJson() {
    return {'backupId': backupId, 'userId': userId};
  }
}
