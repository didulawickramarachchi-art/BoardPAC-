class AttachmentModel {
  final int id;
  final int paperId;
  final String fileName;
  final String filePath;
  final int? displayOrder;
  final String? currentReaction;
  final Map<String, int> reactionCounts;

  AttachmentModel({
    required this.id,
    required this.paperId,
    required this.fileName,
    required this.filePath,
    this.displayOrder,
    this.currentReaction,
    required this.reactionCounts,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'],
      paperId: json['paperId'],
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      displayOrder: json['displayOrder'],
      currentReaction: json['currentReaction'],
      reactionCounts: (json['reactionCounts'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );
  }
}
