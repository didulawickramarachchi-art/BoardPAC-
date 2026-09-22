import { describe, expect, it } from 'vitest'
import { normalizeRole, permissionsFor } from './permissions'

describe('Flutter-compatible role access', () => {
  it('normalizes backend role aliases', () => {
    expect(normalizeRole('SUPER_ADMIN')).toBe('ADMIN')
    expect(normalizeRole('board-secretary')).toBe('SECRETARY')
    expect(normalizeRole('USER')).toBe('MEMBER')
  })

  it('keeps upload-only secretaries from managing meetings', () => {
    const access = permissionsFor({ role: 'SECRETARY', accessProfile: 'SECRETARY_UPLOAD_ONLY' })
    expect(access.canUploadPapers).toBe(true)
    expect(access.canManageMeetings).toBe(false)
    expect(access.canAnnotatePapers).toBe(false)
  })

  it('matches member comment and annotation profiles', () => {
    expect(permissionsFor({ role: 'MEMBER', accessProfile: 'MEMBER_VIEW_ONLY' }).canCommentPapers).toBe(false)
    expect(permissionsFor({ role: 'MEMBER', accessProfile: 'MEMBER_VIEW_COMMENTS' }).canCommentPapers).toBe(true)
    expect(permissionsFor({ role: 'MEMBER' }).canAnnotatePapers).toBe(true)
  })

  it('limits administration to admins', () => {
    const admin = permissionsFor({ role: 'ADMIN' })
    const secretary = permissionsFor({ role: 'SECRETARY' })
    expect(admin.canManageUsers && admin.canManageDevices && admin.canManageCategories).toBe(true)
    expect(secretary.canManageUsers || secretary.canManageDevices || secretary.canManageCategories).toBe(false)
  })
})
