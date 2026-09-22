export const normalizeRole = role => {
  const value = String(role || 'MEMBER').trim().toUpperCase().replace(/[\s-]+/g, '_')
  if (['ADMIN', 'SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM'].includes(value)) return 'ADMIN'
  if (['SECRETARY', 'BOARD_SECRETARY', 'ORGANIZER'].includes(value)) return 'SECRETARY'
  return 'MEMBER'
}

const defaults = { ADMIN: 'BOARD_ADMINISTRATOR', SECRETARY: 'BOARD_SECRETARY', MEMBER: 'MEMBER' }

export const normalizeProfile = (profile, role) =>
  String(profile || defaults[normalizeRole(role)]).trim().toUpperCase().replace(/[\s-]+/g, '_')

export const permissionsFor = user => {
  const role = normalizeRole(user?.role)
  const profile = normalizeProfile(user?.accessProfile, role)
  const admin = role === 'ADMIN'
  const secretary = role === 'SECRETARY'
  const member = role === 'MEMBER'
  const canManageMeetings = secretary && profile !== 'SECRETARY_UPLOAD_ONLY'
  const canApprovePapers = profile === 'BOARD_SECRETARY' || profile === 'MEMBER'
  return {
    role, profile,
    canManageUsers: admin, canViewUsers: admin, canManagePrivileges: admin, canManageDevices: admin,
    canViewMeetings: secretary || member, canManageMeetings,
    canViewPapers: secretary || member, canUploadPapers: secretary,
    canCommentPapers: ['BOARD_SECRETARY', 'SECRETARY_ASSISTANT', 'MEMBER', 'MEMBER_VIEW_COMMENTS'].includes(profile),
    canApprovePapers, canAnnotatePapers: profile === 'BOARD_SECRETARY' || profile === 'MEMBER',
    canViewPendingApprovals: admin || canApprovePapers, canViewReports: admin || canApprovePapers,
    canManageSettings: admin, canManageBoardSetup: secretary && canManageMeetings,
    canViewCategories: true, canManageCategories: admin,
    canViewSubcategories: true, canManageSubcategories: admin,
  }
}

export const can = (user, permission) => Boolean(permissionsFor(user)[permission])
