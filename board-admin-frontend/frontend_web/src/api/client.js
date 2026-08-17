import axios from 'axios'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081/api',
  timeout: 20000,
})
let refreshRequest
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})
api.interceptors.response.use(response => response, async error => {
  const request = error.config
  const refreshToken = localStorage.getItem('refreshToken')
  if (error.response?.status !== 401 || request?._retry || !refreshToken || request?.url?.includes('/tokens/refresh')) return Promise.reject(error)
  request._retry = true
  try {
    refreshRequest ||= api.post('/tokens/refresh', { refreshToken }).finally(() => { refreshRequest = null })
    const { data } = await refreshRequest
    const token = data.accessToken || data.token
    if (!token) throw error
    localStorage.setItem('accessToken', token)
    request.headers.Authorization = `Bearer ${token}`
    return api(request)
  } catch (refreshError) {
    localStorage.removeItem('accessToken'); localStorage.removeItem('refreshToken'); localStorage.removeItem('currentUser')
    if (window.location.pathname !== '/login') window.location.assign('/login')
    return Promise.reject(refreshError)
  }
})
export const errorMessage = (error) => error.response?.data?.message || error.response?.data?.error || error.message || (error.code === 'ERR_NETWORK' ? 'Cannot connect to the server.' : 'Something went wrong. Please try again.')
