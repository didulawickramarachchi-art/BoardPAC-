class ParticipantOptionModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? displayName;
  final bool isParticipant;
  final bool isEligible;

  const ParticipantOptionModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.displayName,
    required this.isParticipant,
    required this.isEligible,
  });

  factory ParticipantOptionModel.fromJson(Map<String, dynamic> json) {
    return ParticipantOptionModel(
      id: json['id'],
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      displayName: json['displayName'],
      isParticipant: json['participant'] ?? false,
      isEligible: json['eligible'] ?? false,
    );
  }
}
