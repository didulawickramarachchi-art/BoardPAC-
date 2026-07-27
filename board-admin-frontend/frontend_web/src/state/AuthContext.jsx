import { createContext, useContext, useMemo, useState } from 'react'
import { api } from '../api/client'

const AuthContext = createContext(null)
export const normalizeRole = (role) => {
  const value = String(role || 'MEMBER').trim().toUpperCase().replace(/[\s-]+/g, '_')
  if (['SUPER_ADMIN', 'BOARD_ADMIN', 'ADMIN', 'SUPPORT_TEAM'].includes(value)) return 'ADMIN'
  if (['BOARD_SECRETARY', 'ORGANIZER', 'SECRETARY'].includes(value)) return 'SECRETARY'
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
  const login = async (body) => { const { data } = await api.post('/auth/login', body); if (data.requires2FA || data.twoFactorRequired) { setChallenge({ username: body.username }); return true } save(data); return false }
  const verify = async (code) => { const { data } = await api.post('/auth/verify-2fa', { username: challenge?.username, code }); save(data) }
  const logout = () => { localStorage.clear(); sessionStorage.clear(); setUser(null) }
  const value = useMemo(() => ({ user, role: normalizeRole(user?.role), challenge, login, verify, logout }), [user, challenge])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
export const useAuth = () => useContext(AuthContext)
