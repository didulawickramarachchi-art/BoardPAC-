class AgendaItemModel {
  final int id;
  final int? sectionId;
  final String itemType;
  final String title;
  final String? numberLabel;
  final int? displayOrder;
  final String? description;

  AgendaItemModel({
    required this.id,
    this.sectionId,
    required this.itemType,
    required this.title,
    this.numberLabel,
    this.displayOrder,
    this.description,
  });

  factory AgendaItemModel.fromJson(Map<String, dynamic> json) {
    return AgendaItemModel(
      id: json['id'],
      sectionId: (json['sectionId'] as num?)?.toInt(),
      itemType: json['itemType'] ?? '',
      title: json['title'] ?? '',
      numberLabel: json['numberLabel'],
      displayOrder: json['displayOrder'],
      description: json['description'],
    );
  }
}
