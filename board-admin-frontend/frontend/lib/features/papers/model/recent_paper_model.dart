import 'paper_model.dart';

class RecentPaperModel {
  final PaperModel paper;
  final int lastPage;
  final int? totalPages;
  final bool completed;
  final DateTime? lastOpenedAt;

  const RecentPaperModel({
    required this.paper,
    required this.lastPage,
    this.totalPages,
    required this.completed,
    this.lastOpenedAt,
  });

  factory RecentPaperModel.fromJson(Map<String, dynamic> json) =>
      RecentPaperModel(
        paper: PaperModel.fromJson({...json, 'id': json['paperId']}),
        lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
        totalPages: (json['totalPages'] as num?)?.toInt(),
        completed: json['completed'] == true,
        lastOpenedAt: DateTime.tryParse(json['lastOpenedAt']?.toString() ?? ''),
      );
}
