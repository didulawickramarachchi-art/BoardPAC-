import { describe, expect, it } from 'vitest'
import { meetingHistoryParams, pagedReportParams } from './reportParams'

describe('report query helpers', () => {
  it('trims optional usernames', () => expect(pagedReportParams({ page: 2, username: ' ada ' })).toEqual({ page: 2, size: 10, username: 'ada' }))
  it('omits blank meeting history filters', () => expect(meetingHistoryParams({ categoryId: 3, from: '2026-01-01' })).toEqual({ categoryId: 3, from: '2026-01-01' }))
})
