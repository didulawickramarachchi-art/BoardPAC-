export const isValidEmail = value => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || '').trim())

export const passwordRequirements = value => {
  const password = String(value || '')
  return {
    validLength: password.length >= 8 && password.length <= 128,
    hasUppercase: /[A-Z]/.test(password),
    hasLowercase: /[a-z]/.test(password),
    hasNumber: /\d/.test(password),
  }
}

export const validateResetForm = (password, confirmation) => {
  const requirements = passwordRequirements(password)
  if (!requirements.validLength) return 'Password must contain between 8 and 128 characters.'
  if (!requirements.hasUppercase || !requirements.hasLowercase || !requirements.hasNumber) return 'Password must contain uppercase, lowercase, and a number.'
  if (password !== confirmation) return 'Passwords do not match.'
  return ''
}

export const readResetToken = search => new URLSearchParams(search).get('token')?.trim() || ''

export const removeResetTokenFromHistory = (location, history) => {
  const params = new URLSearchParams(location.search)
  if (!params.has('token')) return false
  params.delete('token')
  const query = params.toString()
  history.replaceState(history.state, '', `${location.pathname}${query ? `?${query}` : ''}${location.hash || ''}`)
  return true
}
