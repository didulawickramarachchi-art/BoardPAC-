class AttachmentModel {
  final int id;
  final int paperId;
  final String fileName;
  final String filePath;
  final int? displayOrder;

  AttachmentModel({
    required this.id,
    required this.paperId,
    required this.fileName,
    required this.filePath,
    this.displayOrder,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'],
      paperId: json['paperId'],
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      displayOrder: json['displayOrder'],
    );
  }
}
