class ActionItemModel {
  final int id;
  final String title;
  final String? description;
  final int assigneeUserId;
  final String assigneeUsername;
  final String createdByUsername;
  final DateTime? dueDate;
  final String status;
  final String? completionNote;
  final bool editableByCurrentUser;
  const ActionItemModel({
    required this.id,
    required this.title,
    this.description,
    required this.assigneeUserId,
    required this.assigneeUsername,
    required this.createdByUsername,
    this.dueDate,
    required this.status,
    this.completionNote,
    required this.editableByCurrentUser,
  });
  factory ActionItemModel.fromJson(Map<String, dynamic> j) => ActionItemModel(
    id: (j['id'] as num).toInt(),
    title: j['title'] ?? '',
    description: j['description'],
    assigneeUserId: (j['assigneeUserId'] as num).toInt(),
    assigneeUsername: j['assigneeUsername'] ?? '',
    createdByUsername: j['createdByUsername'] ?? '',
    dueDate: DateTime.tryParse(j['dueDate']?.toString() ?? ''),
    status: j['status'] ?? 'OPEN',
    completionNote: j['completionNote'],
    editableByCurrentUser: j['editableByCurrentUser'] ?? false,
  );
}
