import { describe, expect, it, vi } from 'vitest'
import { downloadProtectedPaper, fetchProtectedPaper, preparePaperPayload } from './paperPayloads'

describe('paper workflow helpers', () => {
  it('uploads the primary file before building a paper request', async () => {
    const file = { name: 'pack.pdf' }
    const upload = vi.fn().mockResolvedValue('/uploads/pack.pdf')
    await expect(preparePaperPayload({ meetingId: '4', agendaItemId: '', paperType: 'approval', title: ' Pack ', sourceFile: file }, { editing: false }, upload)).resolves.toEqual({
      meetingId: 4,
      agendaItemId: null,
      paperType: 'APPROVAL',
      title: 'Pack',
      referenceNumber: null,
      filePath: '/uploads/pack.pdf',
      fileName: 'pack.pdf',
      versionNumber: 1,
      requiresApproval: false,
      isMainPaper: false,
      disclaimerMessage: null,
    })
    expect(upload).toHaveBeenCalledWith({ file, meetingId: 4 })
  })

  it('rejects incomplete paper requests before calling the API', async () => {
    const file = { name: 'pack.pdf' }
    await expect(preparePaperPayload({ meetingId: '', paperType: 'APPROVAL', title: 'Pack', sourceFile: file }, vi.fn())).rejects.toThrow('Select a meeting')
    await expect(preparePaperPayload({ meetingId: 4, paperType: 'APPROVAL', title: 'Pack', sourceFile: file }, vi.fn().mockResolvedValue(''))).rejects.toThrow('without returning a file path')
  })

  it('acknowledges delivery only after a successful protected download', async () => {
    const apiClient = { get: vi.fn().mockResolvedValue({ data: '/secure/pack.pdf' }), post: vi.fn().mockResolvedValue({}) }
    const downloader = vi.fn().mockResolvedValue()
    await downloadProtectedPaper({ paper: { id: 8, fileName: 'pack.pdf' }, userId: 2, apiClient, downloader })
    expect(downloader).toHaveBeenCalledWith('/secure/pack.pdf', 'pack.pdf')
    expect(apiClient.post).toHaveBeenCalledWith('/pack-delivery/paper/8/downloaded')
  })

  it('does not acknowledge a failed download', async () => {
    const apiClient = { get: vi.fn().mockResolvedValue({ data: '/secure/pack.pdf' }), post: vi.fn() }
    await expect(downloadProtectedPaper({ paper: { id: 8 }, userId: 2, apiClient, downloader: vi.fn().mockRejectedValue(new Error('failed')) })).rejects.toThrow('failed')
    expect(apiClient.post).not.toHaveBeenCalled()
  })

  it('loads the protected paper as a blob for browser viewing', async () => {
    const pdf = new Blob(['pdf'], { type: 'application/pdf' })
    const apiClient = {
      get: vi.fn()
        .mockResolvedValueOnce({ data: '/api/files/papers/pack.pdf' })
        .mockResolvedValueOnce({ data: pdf }),
    }

    await expect(fetchProtectedPaper({ paperId: 8, userId: 2, apiClient })).resolves.toBe(pdf)
    expect(apiClient.get).toHaveBeenNthCalledWith(1, '/secure-files/papers/8', {
      params: { userId: 2, action: 'VIEW', channel: 'WEB' },
    })
    expect(apiClient.get).toHaveBeenNthCalledWith(2, '/api/files/papers/pack.pdf', { responseType: 'blob' })
  })
})
