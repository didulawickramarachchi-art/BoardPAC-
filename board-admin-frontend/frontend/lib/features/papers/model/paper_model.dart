class PaperModel {
  final int id;
  final int? agendaItemId;
  final String title;
  final String paperType;
  final String? referenceNumber;
  final String? filePath;
  final String? fileName;
  final int? versionNumber;
  final bool requiresApproval;
  final bool isMainPaper;
  final int? rootPaperId;
  final bool currentVersion;
  final String? revisionNote;
  final DateTime? createdAt;

  PaperModel({
    required this.id,
    this.agendaItemId,
    required this.title,
    required this.paperType,
    this.referenceNumber,
    this.filePath,
    this.fileName,
    this.versionNumber,
    required this.requiresApproval,
    required this.isMainPaper,
    this.rootPaperId,
    this.currentVersion = true,
    this.revisionNote,
    this.createdAt,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    return PaperModel(
      id: json['id'],
      agendaItemId: (json['agendaItemId'] as num?)?.toInt(),
      title: json['title'] ?? '',
      paperType: json['paperType'] ?? '',
      referenceNumber: json['referenceNumber'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      versionNumber: json['versionNumber'],
      requiresApproval: json['requiresApproval'] ?? false,
      isMainPaper: json['mainPaper'] ?? json['isMainPaper'] ?? false,
      rootPaperId: (json['rootPaperId'] as num?)?.toInt(),
      currentVersion: json['currentVersion'] ?? true,
      revisionNote: json['revisionNote'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
