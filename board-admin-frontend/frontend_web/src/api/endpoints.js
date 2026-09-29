export const AUTH_ENDPOINTS = Object.freeze({
  login: '/auth/login',
  verifyTwoFactor: '/auth/verify-2fa',
  requestPasswordReset: '/auth/password-reset/request',
  resetPassword: '/auth/reset-password',
  refreshToken: '/tokens/refresh',
})

export const FILE_ENDPOINTS = Object.freeze({
  upload: '/files/upload',
})

export const USER_ENDPOINTS = Object.freeze({
  current: '/users/me',
  twoFactor: '/users/me/two-factor',
  profilePicture: '/users/me/profile-picture',
})

