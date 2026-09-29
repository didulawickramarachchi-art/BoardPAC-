export const STORAGE_KEYS = Object.freeze({
  accessToken: 'accessToken',
  refreshToken: 'refreshToken',
  currentUser: 'currentUser',
  deviceId: 'deviceInstallationId',
})

const browserStorage = () => {
  try {
    return globalThis.localStorage
  } catch {
    return null
  }
}

export const readStoredValue = key => browserStorage()?.getItem(key) || ''

export const readStoredUser = () => {
  const value = readStoredValue(STORAGE_KEYS.currentUser)
  if (!value) return null
  try {
    return JSON.parse(value)
  } catch {
    browserStorage()?.removeItem(STORAGE_KEYS.currentUser)
    return null
  }
}

export const storeTokens = ({ accessToken, refreshToken }) => {
  const storage = browserStorage()
  if (!storage) return
  if (accessToken) storage.setItem(STORAGE_KEYS.accessToken, accessToken)
  if (refreshToken) storage.setItem(STORAGE_KEYS.refreshToken, refreshToken)
}

export const storeAuthSession = ({ user, accessToken, refreshToken }) => {
  storeTokens({ accessToken, refreshToken })
  if (user) browserStorage()?.setItem(STORAGE_KEYS.currentUser, JSON.stringify(user))
}

export const clearAuthSession = () => {
  const storage = browserStorage()
  if (!storage) return
  storage.removeItem(STORAGE_KEYS.accessToken)
  storage.removeItem(STORAGE_KEYS.refreshToken)
  storage.removeItem(STORAGE_KEYS.currentUser)
}

export const getAccessToken = () => readStoredValue(STORAGE_KEYS.accessToken)
export const getRefreshToken = () => readStoredValue(STORAGE_KEYS.refreshToken)

