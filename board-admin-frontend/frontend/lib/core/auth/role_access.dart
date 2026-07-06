const String _defaultRole = 'MEMBER';

String normalizeRole(String? role) {
  final normalized = role?.toString().trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');

  switch (normalized) {
    case 'SUPER_ADMIN':
    case 'BOARD_ADMIN':
    case 'ADMIN':
      return 'ADMIN';
    case 'BOARD_SECRETARY':
    case 'ORGANIZER':
    case 'SECRETARY':
      return 'SECRETARY';
    case 'MEMBER':
    case 'USER':
      return 'MEMBER';
    case 'SUPPORT_TEAM':
      return 'ADMIN';
    default:
      return normalized?.isNotEmpty == true ? normalized! : _defaultRole;
  }
}

bool isAdmin(String? role) => normalizeRole(role) == 'ADMIN';
bool isSecretary(String? role) => normalizeRole(role) == 'SECRETARY';
bool isMember(String? role) => normalizeRole(role) == 'MEMBER';

class RoleAccess {
  final String role;

  const RoleAccess(this.role);

  bool get isAdmin => _roleKey == 'ADMIN';
  bool get isSecretary => _roleKey == 'SECRETARY';
  bool get isMember => _roleKey == 'MEMBER';

  bool get canManageUsers => isAdmin;
  bool get canViewUsers => isAdmin;
  bool get canManagePrivileges => isAdmin;
  bool get canManageDevices => isAdmin;

  bool get canViewMeetings => isSecretary || isMember;
  bool get canManageMeetings => isSecretary;

  bool get canViewPapers => isSecretary || isMember;
  bool get canUploadPapers => isSecretary;
  bool get canCommentPapers => isSecretary;

  bool get canViewReports => isAdmin;
  bool get canManageSettings => isAdmin;
  bool get canManageBoardSetup => isSecretary;
  bool get canViewCategories => isSecretary || isMember;
  bool get canManageCategories => isSecretary;
  bool get canViewSubcategories => isSecretary || isMember;
  bool get canManageSubcategories => isSecretary;

  String get _roleKey => normalizeRole(role);
}
