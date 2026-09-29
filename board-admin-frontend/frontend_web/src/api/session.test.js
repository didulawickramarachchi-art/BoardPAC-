import { beforeEach, describe, expect, it, vi } from 'vitest'
import { clearAuthSession, getAccessToken, getRefreshToken, readStoredUser, STORAGE_KEYS, storeAuthSession, storeTokens } from './session'

const createStorage = () => {
  const values = new Map()
  return {
    getItem: vi.fn(key => values.get(key) ?? null),
    setItem: vi.fn((key, value) => values.set(key, String(value))),
    removeItem: vi.fn(key => values.delete(key)),
  }
}

describe('BoardPAC session storage', () => {
  beforeEach(() => {
    vi.stubGlobal('localStorage', createStorage())
  })

  it('stores and reads auth state', () => {
    const user = { id: 7, username: 'member' }
    storeAuthSession({ user, accessToken: 'access', refreshToken: 'refresh' })
    expect(getAccessToken()).toBe('access')
    expect(getRefreshToken()).toBe('refresh')
    expect(readStoredUser()).toEqual(user)
  })

  it('rotates tokens without erasing the current user', () => {
    storeAuthSession({ user: { id: 1 }, accessToken: 'old', refreshToken: 'old-refresh' })
    storeTokens({ accessToken: 'new', refreshToken: 'new-refresh' })
    expect(getAccessToken()).toBe('new')
    expect(getRefreshToken()).toBe('new-refresh')
    expect(readStoredUser()).toEqual({ id: 1 })
  })

  it('clears only BoardPAC auth values and preserves device identity', () => {
    localStorage.setItem(STORAGE_KEYS.deviceId, 'device-1')
    localStorage.setItem('unrelated', 'keep-me')
    storeAuthSession({ user: { id: 1 }, accessToken: 'a', refreshToken: 'r' })
    clearAuthSession()
    expect(localStorage.getItem(STORAGE_KEYS.deviceId)).toBe('device-1')
    expect(localStorage.getItem('unrelated')).toBe('keep-me')
    expect(readStoredUser()).toBeNull()
  })

  it('drops an invalid cached user value', () => {
    localStorage.setItem(STORAGE_KEYS.currentUser, '{invalid')
    expect(readStoredUser()).toBeNull()
    expect(localStorage.removeItem).toHaveBeenCalledWith(STORAGE_KEYS.currentUser)
  })
})

