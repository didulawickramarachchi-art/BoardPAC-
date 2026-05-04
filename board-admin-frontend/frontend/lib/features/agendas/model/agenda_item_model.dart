class AgendaItemModel {
  final int id;
  final String itemType;
  final String title;
  final String? numberLabel;
  final int? displayOrder;
  final String? description;

  AgendaItemModel({
    required this.id,
    required this.itemType,
    required this.title,
    this.numberLabel,
    this.displayOrder,
    this.description,
  });

  factory AgendaItemModel.fromJson(Map<String, dynamic> json) {
    return AgendaItemModel(
      id: json['id'],
      itemType: json['itemType'] ?? '',
      title: json['title'] ?? '',
      numberLabel: json['numberLabel'],
      displayOrder: json['displayOrder'],
      description: json['description'],
    );
  }
}
