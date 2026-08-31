class PaperReadStateModel {
  final int paperId;
  final bool seen;
  final DateTime? firstOpenedAt;
  final DateTime? lastOpenedAt;
  final int lastPage;
  final int? totalPages;
  final bool completed;

  const PaperReadStateModel({
    required this.paperId,
    required this.seen,
    this.firstOpenedAt,
    this.lastOpenedAt,
    required this.lastPage,
    this.totalPages,
    required this.completed,
  });

  factory PaperReadStateModel.fromJson(Map<String, dynamic> json) =>
      PaperReadStateModel(
        paperId: (json['paperId'] as num).toInt(),
        seen: json['seen'] == true,
        firstOpenedAt: DateTime.tryParse(
          json['firstOpenedAt']?.toString() ?? '',
        ),
        lastOpenedAt: DateTime.tryParse(json['lastOpenedAt']?.toString() ?? ''),
        lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
        totalPages: (json['totalPages'] as num?)?.toInt(),
        completed: json['completed'] == true,
      );
}
