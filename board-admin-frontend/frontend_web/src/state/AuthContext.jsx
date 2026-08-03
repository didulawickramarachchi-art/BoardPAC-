import { createContext, useContext, useMemo, useState } from 'react'
import { api } from '../api/client'

const AuthContext = createContext(null)
const DEVICE_ID_KEY = 'deviceInstallationId'
const deviceIdentity = () => {
  let deviceId = localStorage.getItem(DEVICE_ID_KEY)
  if (!deviceId) {
    deviceId = crypto.randomUUID()
    localStorage.setItem(DEVICE_ID_KEY, deviceId)
  }
  return {
    deviceId,
    deviceInfo: `${navigator.platform || 'Web'} browser`,
    boardPacVersion: '1.0.0',
    osVersion: navigator.userAgent.slice(0, 500),
    description: 'BoardPAC web installation',
  }
}
export const normalizeRole = (role) => {
  const value = String(role || 'MEMBER').trim().toUpperCase().replace(/[\s-]+/g, '_')
  if (value === 'ADMIN') return 'ADMIN'
  if (value === 'SECRETARY') return 'SECRETARY'
  return 'MEMBER'
}
const stored = () => { try { return JSON.parse(localStorage.getItem('currentUser')) } catch { return null } }
export function AuthProvider({ children }) {
  const [user, setUser] = useState(stored)
  const [challenge, setChallenge] = useState(null)
  const save = (data) => {
    const next = { id: data.userId || data.id, username: data.username, displayName: data.displayName || data.username, role: normalizeRole(data.role) }
    localStorage.setItem('accessToken', data.accessToken || data.token || '')
    if (data.refreshToken) localStorage.setItem('refreshToken', data.refreshToken)
    localStorage.setItem('currentUser', JSON.stringify(next)); setUser(next)
  }
  const login = async (body) => {
    const identity = deviceIdentity()
    const { data } = await api.post('/auth/login', { ...body, ...identity })
    if (data.requires2FA || data.twoFactorRequired) {
      setChallenge({ username: body.username, identity })
      return true
    }
    if (!(data.accessToken || data.token)) throw new Error(data.message || 'This device is not approved')
    save(data)
    return false
  }
  const verify = async (code) => {
    const { data } = await api.post('/auth/verify-2fa', { username: challenge?.username, code, ...(challenge?.identity || deviceIdentity()) })
    if (!(data.accessToken || data.token)) throw new Error(data.message || 'This device is not approved')
    save(data)
  }
  const logout = () => {
    const deviceId = localStorage.getItem(DEVICE_ID_KEY)
    localStorage.clear()
    if (deviceId) localStorage.setItem(DEVICE_ID_KEY, deviceId)
    sessionStorage.clear()
    setUser(null)
  }
  const value = useMemo(() => ({ user, role: normalizeRole(user?.role), challenge, login, verify, logout }), [user, challenge])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
export const useAuth = () => useContext(AuthContext)
