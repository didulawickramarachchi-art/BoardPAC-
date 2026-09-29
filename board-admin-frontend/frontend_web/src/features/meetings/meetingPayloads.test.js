import { describe, expect, it, vi } from 'vitest'
import { actionStatusPayload, orderedIdsAfterMove, prepareMeetingPayload, rsvpPayload } from './meetingPayloads'

describe('meeting workflow payloads', () => {
  it('moves agenda IDs while respecting list boundaries', () => {
    const items = [{ id: 2, displayOrder: 2 }, { id: 1, displayOrder: 1 }, { id: 3, displayOrder: 3 }]
    expect(orderedIdsAfterMove(items, 2, -1)).toEqual([2, 1, 3])
    expect(orderedIdsAfterMove(items, 1, -1)).toEqual([1, 2, 3])
  })

  it('normalizes RSVP and action-item notes', () => {
    expect(rsvpPayload('DECLINED', '  Scheduling conflict ')).toEqual({ participantStatus: 'DECLINED', statusReason: 'Scheduling conflict' })
    expect(actionStatusPayload('COMPLETED', '  Done ')).toEqual({ status: 'COMPLETED', completionNote: 'Done' })
  })

  it('uploads a selected meeting image before creating the meeting', async () => {
    const imageFile = { name: 'meeting.png' }
    const uploader = vi.fn().mockResolvedValue('/uploads/meeting.png')
    await expect(prepareMeetingPayload({ title: 'Board meeting', imageFile }, uploader)).resolves.toEqual({ title: 'Board meeting', imageUrl: '/uploads/meeting.png' })
    expect(uploader).toHaveBeenCalledWith({ file: imageFile })
  })
})
