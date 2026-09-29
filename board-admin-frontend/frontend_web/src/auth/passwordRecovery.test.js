import { describe, expect, it, vi } from 'vitest'
import { isValidEmail, passwordRequirements, readResetToken, removeResetTokenFromHistory, validateResetForm } from './passwordRecovery'

describe('password recovery helpers', () => {
  it('validates email addresses without changing the submitted value', () => {
    expect(isValidEmail('member@example.com')).toBe(true)
    expect(isValidEmail(' member@example.com ')).toBe(true)
    expect(isValidEmail('not-an-email')).toBe(false)
  })

  it('matches the backend password policy', () => {
    expect(passwordRequirements('BoardPac9')).toEqual({ validLength: true, hasUppercase: true, hasLowercase: true, hasNumber: true })
    expect(validateResetForm('short1A', 'short1A')).toContain('8 and 128')
    expect(validateResetForm('alllowercase9', 'alllowercase9')).toContain('uppercase')
    expect(validateResetForm('BoardPac9', 'BoardPac8')).toBe('Passwords do not match.')
    expect(validateResetForm('BoardPac9', 'BoardPac9')).toBe('')
  })

  it('captures and removes only the reset token from browser history', () => {
    expect(readResetToken('?source=email&token=secret-value')).toBe('secret-value')
    const history = { state: { key: 1 }, replaceState: vi.fn() }
    const removed = removeResetTokenFromHistory({ pathname: '/reset-password', search: '?source=email&token=secret-value', hash: '' }, history)
    expect(removed).toBe(true)
    expect(history.replaceState).toHaveBeenCalledWith(history.state, '', '/reset-password?source=email')
  })
})
