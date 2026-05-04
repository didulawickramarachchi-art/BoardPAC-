class AttachmentRequest {
  final int paperId;
  final String fileName;
  final String filePath;
  final int? displayOrder;

  AttachmentRequest({
    required this.paperId,
    required this.fileName,
    required this.filePath,
    this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'fileName': fileName,
      'filePath': filePath,
      'displayOrder': displayOrder,
    };
  }
}
