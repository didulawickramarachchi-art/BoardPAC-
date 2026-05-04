class PaperModel {
  final int id;
  final String title;
  final String paperType;
  final String? referenceNumber;
  final String? filePath;
  final String? fileName;
  final int? versionNumber;
  final bool requiresApproval;
  final bool isMainPaper;

  PaperModel({
    required this.id,
    required this.title,
    required this.paperType,
    this.referenceNumber,
    this.filePath,
    this.fileName,
    this.versionNumber,
    required this.requiresApproval,
    required this.isMainPaper,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    return PaperModel(
      id: json['id'],
      title: json['title'] ?? '',
      paperType: json['paperType'] ?? '',
      referenceNumber: json['referenceNumber'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      versionNumber: json['versionNumber'],
      requiresApproval: json['requiresApproval'] ?? false,
      isMainPaper: json['mainPaper'] ?? json['isMainPaper'] ?? false,
    );
  }
}
