import { describe, expect, it } from 'vitest'
import { errorMessage, normalizeApiBaseUrl } from './client'

describe('API client helpers', () => {
  it('normalizes configured base URLs', () => {
    expect(normalizeApiBaseUrl(' https://board.example/api/// ')).toBe('https://board.example/api')
    expect(normalizeApiBaseUrl('')).toBe('http://localhost:8081/api')
  })

  it('prefers backend field validation messages', () => {
    const error = { response: { data: { message: 'Validation failed', validationErrors: { email: 'must be valid' } } } }
    expect(errorMessage(error)).toBe('email: must be valid')
  })

  it('handles network, text and standard backend errors', () => {
    expect(errorMessage({ code: 'ERR_NETWORK', message: 'Network Error' })).toBe('Cannot connect to the server.')
    expect(errorMessage({ response: { data: 'Upload rejected' } })).toBe('Upload rejected')
    expect(errorMessage({ response: { data: { message: 'Not allowed' } } })).toBe('Not allowed')
  })
})
