class AnnotationModel {
  final int id;
  final int paperId;
  final int userId;
  final String annotationType;
  final String annotationDataJson;
  final int? pageNumber;

  AnnotationModel({
    required this.id,
    required this.paperId,
    required this.userId,
    required this.annotationType,
    required this.annotationDataJson,
    this.pageNumber,
  });

  factory AnnotationModel.fromJson(Map<String, dynamic> json) {
    return AnnotationModel(
      id: json['id'],
      paperId: json['paperId'],
      userId: json['userId'],
      annotationType: json['annotationType'] ?? '',
      annotationDataJson: json['annotationDataJson'] ?? '',
      pageNumber: json['pageNumber'],
    );
  }
}
