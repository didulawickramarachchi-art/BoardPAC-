class PackDeliveryModel {
  final int paperId;
  final String paperTitle;
  final int userId;
  final String username;
  final String deliveryStatus;

  PackDeliveryModel({
    required this.paperId,
    required this.paperTitle,
    required this.userId,
    required this.username,
    required this.deliveryStatus,
  });

  factory PackDeliveryModel.fromJson(Map<String, dynamic> json) {
    return PackDeliveryModel(
      paperId: json['paperId'],
      paperTitle: json['paperTitle'] ?? '',
      userId: json['userId'],
      username: json['username'] ?? '',
      deliveryStatus: json['deliveryStatus'] ?? '',
    );
  }
}
