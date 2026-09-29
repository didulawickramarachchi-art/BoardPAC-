import { api } from './client'
import { AUTH_ENDPOINTS } from './endpoints'

export const requestPasswordReset = email => api.post(AUTH_ENDPOINTS.requestPasswordReset, { email })

export const resetPassword = (token, newPassword) => api.post(AUTH_ENDPOINTS.resetPassword, { token, newPassword })
