import axios from 'axios'
import { AUTH_ENDPOINTS } from './endpoints'
import { clearAuthSession, getAccessToken, getRefreshToken, storeTokens } from './session'
import { validationMessages } from './response'

export const normalizeApiBaseUrl = value => String(value || 'http://localhost:8081/api').trim().replace(/\/+$/, '')

const baseURL = normalizeApiBaseUrl(import.meta.env.VITE_API_BASE_URL)
export const api = axios.create({
  baseURL,
  timeout: 20000,
})

const refreshClient = axios.create({ baseURL, timeout: 20000 })
let refreshRequest

const isPublicAuthRequest = url => Object.values(AUTH_ENDPOINTS).some(path => String(url || '').includes(path))

const redirectToLogin = () => {
  if (typeof window === 'undefined') return
  const publicPaths = ['/login', '/forgot-password', '/reset-password']
  if (!publicPaths.includes(window.location.pathname)) window.location.assign('/login')
}

api.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token && !isPublicAuthRequest(config.url)) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(response => response, async error => {
  const request = error.config
  const refreshToken = getRefreshToken()
  if (error.response?.status !== 401 || request?._retry || isPublicAuthRequest(request?.url)) return Promise.reject(error)
  if (!refreshToken) {
    clearAuthSession()
    redirectToLogin()
    return Promise.reject(error)
  }
  request._retry = true
  try {
    refreshRequest ||= refreshClient.post(AUTH_ENDPOINTS.refreshToken, { refreshToken }).finally(() => { refreshRequest = null })
    const { data } = await refreshRequest
    const token = data.accessToken || data.token
    if (!token) throw error
    storeTokens({ accessToken: token, refreshToken: data.refreshToken })
    request.headers.Authorization = `Bearer ${token}`
    return api(request)
  } catch (refreshError) {
    clearAuthSession()
    redirectToLogin()
    return Promise.reject(refreshError)
  }
})

export const errorMessage = error => {
  if (error?.code === 'ERR_CANCELED') return 'Request cancelled.'
  if (error?.code === 'ERR_NETWORK' || (!error?.response && error?.request)) return 'Cannot connect to the server.'
  const data = error?.response?.data
  const fieldMessages = validationMessages(data)
  if (fieldMessages.length) return fieldMessages.join(' ')
  if (typeof data === 'string' && data.trim()) return data.trim()
  return data?.message || data?.error || error?.message || 'Something went wrong. Please try again.'
}
