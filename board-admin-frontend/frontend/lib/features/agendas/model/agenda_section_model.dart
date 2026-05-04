class AgendaSectionModel {
  final int id;
  final String title;
  final String? numberLabel;
  final int? displayOrder;

  AgendaSectionModel({
    required this.id,
    required this.title,
    this.numberLabel,
    this.displayOrder,
  });

  factory AgendaSectionModel.fromJson(Map<String, dynamic> json) {
    return AgendaSectionModel(
      id: json['id'],
      title: json['title'] ?? '',
      numberLabel: json['numberLabel'],
      displayOrder: json['displayOrder'],
    );
  }
}
