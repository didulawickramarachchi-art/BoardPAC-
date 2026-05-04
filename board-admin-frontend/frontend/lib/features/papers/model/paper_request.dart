class PaperRequest {
  final int meetingId;
  final int agendaItemId;
  final String paperType;
  final String title;
  final String? referenceNumber;
  final String? filePath;
  final String? fileName;
  final int? versionNumber;
  final bool requiresApproval;
  final bool isMainPaper;
  final String? disclaimerMessage;

  PaperRequest({
    required this.meetingId,
    required this.agendaItemId,
    required this.paperType,
    required this.title,
    this.referenceNumber,
    this.filePath,
    this.fileName,
    this.versionNumber,
    required this.requiresApproval,
    required this.isMainPaper,
    this.disclaimerMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'agendaItemId': agendaItemId,
      'paperType': paperType,
      'title': title,
      'referenceNumber': referenceNumber,
      'filePath': filePath,
      'fileName': fileName,
      'versionNumber': versionNumber,
      'requiresApproval': requiresApproval,
      'isMainPaper': isMainPaper,
      'disclaimerMessage': disclaimerMessage,
    };
  }
}
