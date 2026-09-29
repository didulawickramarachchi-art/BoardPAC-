import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { api } from '../api/client'
import { AUTH_ENDPOINTS, USER_ENDPOINTS } from '../api/endpoints'
import { clearAuthSession, getAccessToken, getRefreshToken, readStoredUser, readStoredValue, STORAGE_KEYS, storeAuthSession, storeTokens } from '../api/session'
import { normalizeRole } from '../auth/permissions'

const AuthContext = createContext(null)
const readChallenge = () => { try { return JSON.parse(sessionStorage.getItem('boardpac_2fa_challenge')) } catch { return null } }
const deviceIdentity = () => {
  let deviceId = readStoredValue(STORAGE_KEYS.deviceId)
  if (!deviceId) {
    deviceId = crypto.randomUUID()
    localStorage.setItem(STORAGE_KEYS.deviceId, deviceId)
  }
  return {
    deviceId,
    deviceInfo: `${navigator.platform || 'Web'} browser`,
    boardPacVersion: '1.0.0',
    osVersion: navigator.userAgent.slice(0, 500),
    description: 'BoardPAC web installation',
  }
}
export { normalizeRole } from '../auth/permissions'

const normalizeUser = data => ({
  ...data,
  id: data.userId || data.id,
  username: data.username,
  displayName: data.displayName || data.username,
  role: normalizeRole(data.role),
  accessProfile: data.accessProfile,
})

export function AuthProvider({ children }) {
  const [user, setUser] = useState(readStoredUser)
  const [challenge, setChallenge] = useState(readChallenge)
  const [initializing, setInitializing] = useState(true)

  const saveUser = useCallback(data => {
    const next = normalizeUser(data)
    storeAuthSession({ user: next })
    setUser(next)
    return next
  }, [])

  const refreshUser = async () => {
    const { data } = await api.get(USER_ENDPOINTS.current)
    return saveUser(data)
  }

  const completeAuthentication = async data => {
    const accessToken = data.accessToken || data.token
    if (!accessToken) throw new Error(data.message || 'Authentication did not return an access token.')
    storeTokens({ accessToken, refreshToken: data.refreshToken })
    try {
      await refreshUser()
      setChallenge(null); sessionStorage.removeItem('boardpac_2fa_challenge')
    } catch (error) {
      clearAuthSession()
      setUser(null)
      throw error
    }
  }

  useEffect(() => {
    let active = true
    const restore = async () => {
      if (!getAccessToken() && !getRefreshToken()) {
        if (active) setInitializing(false)
        return
      }
      try {
        const { data } = await api.get(USER_ENDPOINTS.current)
        if (active) saveUser(data)
      } catch {
        clearAuthSession()
        if (active) setUser(null)
      } finally {
        if (active) setInitializing(false)
      }
    }
    restore()
    return () => { active = false }
  }, [saveUser])

  const login = async (body) => {
    const identity = deviceIdentity()
    const { data } = await api.post(AUTH_ENDPOINTS.login, { ...body, ...identity })
    if (data.requires2FA || data.twoFactorRequired) {
      const nextChallenge={ username: body.username, identity }; setChallenge(nextChallenge); sessionStorage.setItem('boardpac_2fa_challenge',JSON.stringify(nextChallenge))
      return true
    }
    await completeAuthentication(data)
    return false
  }
  const verify = async (code) => {
    const { data } = await api.post(AUTH_ENDPOINTS.verifyTwoFactor, { username: challenge?.username, code, ...(challenge?.identity || deviceIdentity()) })
    await completeAuthentication(data)
  }
  const logout = () => {
    clearAuthSession()
    setUser(null)
    setChallenge(null)
    sessionStorage.removeItem('boardpac_2fa_challenge')
  }
  const value = { user, role: normalizeRole(user?.role), challenge, initializing, login, verify, logout, refreshUser }
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
export const useAuth = () => useContext(AuthContext)
