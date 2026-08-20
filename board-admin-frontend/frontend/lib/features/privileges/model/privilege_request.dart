class PrivilegeRequest {
  final int userId;
  final int subcategoryId;
  final String assignedRole;
  final int? displaySequence;

  PrivilegeRequest({
    required this.userId,
    required this.subcategoryId,
    required this.assignedRole,
    this.displaySequence,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'subcategoryId': subcategoryId,
      'assignedRole': assignedRole,
      'displaySequence': displaySequence,
    };
  }
}
