const String _defaultRole = 'MEMBER';
const String _defaultBoardType = 'MEMBER';

const List<String> supportedRoles = ['ADMIN', 'SECRETARY', 'MEMBER'];
const List<String> supportedBoardTypes = [
  'MEMBER',
  'ORGANIZER',
  'SUPPORT_TEAM',
];

const Map<String, List<String>> accessProfilesByRole = {
  'ADMIN': ['BOARD_ADMINISTRATOR', 'SYSTEM_ADMINISTRATOR'],
  'SECRETARY': [
    'BOARD_SECRETARY',
    'SECRETARY_ASSISTANT',
    'SECRETARY_UPLOAD_ONLY',
  ],
  'MEMBER': ['MEMBER', 'MEMBER_VIEW_ONLY', 'MEMBER_VIEW_COMMENTS'],
};

String normalizeRole(String? role) {
  final normalized = role?.toString().trim().toUpperCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );

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

String normalizeBoardType(String? boardType) {
  final normalized = boardType?.trim().toUpperCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  return supportedBoardTypes.contains(normalized)
      ? normalized!
      : _defaultBoardType;
}

String roleLabel(String? role) => switch (normalizeRole(role)) {
  'ADMIN' => 'Administrator',
  'SECRETARY' => 'Board Secretary',
  'MEMBER' => 'Board Member',
  final value => _titleCase(value),
};

String boardTypeLabel(String? boardType) =>
    switch (normalizeBoardType(boardType)) {
      'ORGANIZER' => 'Organizer',
      'SUPPORT_TEAM' => 'Support Team',
      _ => 'Member',
    };

String boardTypeAccessLabel(String? boardType) =>
    switch (normalizeBoardType(boardType)) {
      'ORGANIZER' => 'Web and device access',
      'SUPPORT_TEAM' => 'Web access only',
      _ => 'Device access only',
    };

List<String> accessProfilesForRole(String? role) =>
    accessProfilesByRole[normalizeRole(role)] ?? const ['MEMBER'];

String defaultAccessProfile(String? role) => accessProfilesForRole(role).first;

String normalizeAccessProfile(String? profile, String? role) {
  final normalized = profile?.trim().toUpperCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  final supported = accessProfilesForRole(role);
  return supported.contains(normalized) ? normalized! : supported.first;
}

String accessProfileLabel(String? profile) => switch (profile?.toUpperCase()) {
  'BOARD_ADMINISTRATOR' => 'Board Administrator',
  'SYSTEM_ADMINISTRATOR' => 'System Administrator',
  'BOARD_SECRETARY' => 'Board Secretary',
  'SECRETARY_ASSISTANT' => 'Secretary Assistant',
  'SECRETARY_UPLOAD_ONLY' => 'Secretary Upload Only',
  'MEMBER_VIEW_ONLY' => 'Member – View Only',
  'MEMBER_VIEW_COMMENTS' => 'Member – View & Comments',
  _ => 'Board Member',
};

String accessProfileDescription(String? profile) =>
    switch (profile?.toUpperCase()) {
      'SYSTEM_ADMINISTRATOR' => 'System configuration and administration',
      'BOARD_ADMINISTRATOR' => 'Users, devices, privileges and reports',
      'SECRETARY_ASSISTANT' => 'Assisted meeting and paper management',
      'SECRETARY_UPLOAD_ONLY' => 'Paper and attachment uploads only',
      'MEMBER_VIEW_ONLY' => 'Read-only meeting and paper access',
      'MEMBER_VIEW_COMMENTS' => 'Read access with comments enabled',
      'BOARD_SECRETARY' => 'Full meeting and agenda management',
      _ => 'Full member participation access',
    };

String _titleCase(String value) => value
    .split('_')
    .map(
      (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');

class RoleAccess {
  final String role;
  final String? accessProfile;

  const RoleAccess(this.role, [this.accessProfile]);

  bool get isAdmin => _roleKey == 'ADMIN';
  bool get isSecretary => _roleKey == 'SECRETARY';
  bool get isMember => _roleKey == 'MEMBER';

  bool get canManageUsers => isAdmin;
  bool get canViewUsers => isAdmin;
  bool get canManagePrivileges => isSecretary;
  bool get canManageDevices => isAdmin;

  bool get canViewMeetings => isSecretary || isMember;
  bool get canManageMeetings =>
      isSecretary && _profileKey != 'SECRETARY_UPLOAD_ONLY';

  bool get canViewPapers => isSecretary || isMember;
  bool get canUploadPapers => isSecretary;
  bool get canCommentPapers =>
      _profileKey == 'BOARD_SECRETARY' ||
      _profileKey == 'SECRETARY_ASSISTANT' ||
      _profileKey == 'MEMBER' ||
      _profileKey == 'MEMBER_VIEW_COMMENTS';
  bool get canApprovePapers =>
      _profileKey == 'BOARD_SECRETARY' || _profileKey == 'MEMBER';
  bool get canAnnotatePapers =>
      _profileKey == 'BOARD_SECRETARY' || _profileKey == 'MEMBER';

  bool get canViewReports => isAdmin;
  bool get canManageSettings => isAdmin;
  bool get canManageBoardSetup => isSecretary && canManageMeetings;
  bool get canViewCategories => isSecretary || isMember;
  bool get canManageCategories => isSecretary;
  bool get canViewSubcategories => isSecretary || isMember;
  bool get canManageSubcategories => isSecretary;

  String get _roleKey => normalizeRole(role);
  String get _profileKey => normalizeAccessProfile(accessProfile, role);
}
