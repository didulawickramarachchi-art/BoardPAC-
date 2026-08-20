class AnnotationRequest {
  final int paperId;
  final int userId;
  final String annotationType;
  final String annotationDataJson;
  final int? pageNumber;

  AnnotationRequest({
    required this.paperId,
    required this.userId,
    required this.annotationType,
    required this.annotationDataJson,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'paperId': paperId,
      'userId': userId,
      'annotationType': annotationType,
      'annotationDataJson': annotationDataJson,
      'pageNumber': pageNumber,
    };
  }
}
