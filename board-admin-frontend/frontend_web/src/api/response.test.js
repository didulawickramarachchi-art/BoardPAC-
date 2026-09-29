import { describe, expect, it } from 'vitest'
import { collectionFrom, tableRowsFrom, uploadedFilePath, validationMessages } from './response'

describe('API response helpers', () => {
  it('normalizes direct and wrapped collections', () => {
    expect(collectionFrom([{ id: 1 }])).toEqual([{ id: 1 }])
    expect(collectionFrom({ content: [{ id: 2 }] })).toEqual([{ id: 2 }])
    expect(collectionFrom({ notifications: [{ id: 3 }] })).toEqual([{ id: 3 }])
    expect(collectionFrom(null)).toEqual([])
  })

  it('keeps singleton report responses usable as table rows', () => {
    expect(tableRowsFrom({ allocated: 10, available: 2 })).toEqual([{ allocated: 10, available: 2 }])
  })

  it('resolves all backend-supported upload response shapes', () => {
    expect(uploadedFilePath('/files/a.pdf')).toBe('/files/a.pdf')
    expect(uploadedFilePath({ fileUrl: '/files/b.pdf' })).toBe('/files/b.pdf')
    expect(uploadedFilePath({ publicUrl: '/files/c.pdf' })).toBe('/files/c.pdf')
  })

  it('formats field validation errors', () => {
    expect(validationMessages({ validationErrors: { email: 'must be valid', title: 'is required' } }))
      .toEqual(['email: must be valid', 'title: is required'])
  })
})

