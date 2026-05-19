class RoleAccess {
  final String role;

  const RoleAccess(this.role);

  bool get isSuperAdmin => _roleKey == 'SUPER_ADMIN';
  bool get isBoardAdmin => _roleKey == 'BOARD_ADMIN';
  bool get isBoardSecretary => _roleKey == 'BOARD_SECRETARY';
  bool get isSupportTeam => _roleKey == 'SUPPORT_TEAM';
  bool get isMember => _roleKey == 'MEMBER' || _roleKey == 'USER';

  bool get canManageUsers => isSuperAdmin || isBoardAdmin;
  bool get canViewUsers => canManageUsers || isSupportTeam;
  bool get canManagePrivileges => isSuperAdmin || isBoardAdmin || isSupportTeam;

  bool get canViewMeetings => isSuperAdmin || isBoardSecretary || isMember;
  bool get canManageMeetings => isSuperAdmin || isBoardSecretary;

  bool get canViewPapers => canViewMeetings;
  bool get canUploadPapers => isSuperAdmin || isBoardSecretary;
  bool get canCommentPapers => isSuperAdmin || isBoardSecretary;

  bool get canViewReports => isSuperAdmin;
  bool get canManageSettings => isSuperAdmin;
  bool get canManageBoardSetup => isSuperAdmin || isBoardSecretary;

  String get _roleKey => normalize(role);

  static String normalize(String role) {
    return role.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }
}
