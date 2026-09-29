import { describe, expect, it, vi } from 'vitest'
import { prepareCategoryPayload, settingInputType, settingOptions } from './adminPayloads'

describe('admin payload helpers', () => {
  it('uploads a selected category image', async () => {
    const file = new File(['image'], 'category.png', { type: 'image/png' })
    const uploader = vi.fn().mockResolvedValue('/uploads/category.png')
    await expect(prepareCategoryPayload({ name: 'Board', imageFile: file }, uploader)).resolves.toEqual({ name: 'Board', imageUrl: '/uploads/category.png' })
  })

  it('preserves an existing category image when no file is selected', async () => {
    await expect(prepareCategoryPayload({ name: 'Board', imageUrl: '/old.png', imageFile: '' })).resolves.toEqual({ name: 'Board', imageUrl: '/old.png' })
  })

  it('detects setting value controls', () => {
    expect(settingInputType('false')).toBe('boolean')
    expect(settingInputType('45')).toBe('number')
    expect(settingInputType('STANDARD')).toBe('text')
    expect(settingOptions('WATERMARK_TYPE')).toContain('NONE')
  })
})
