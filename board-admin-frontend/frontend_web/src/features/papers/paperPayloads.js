import { api } from '../../api/client'
import { downloadFile, uploadFile } from '../../api/files'

export const preparePaperPayload = async (form, optionsOrUploader = {}, uploader = uploadFile) => {
  const upload = typeof optionsOrUploader === 'function' ? optionsOrUploader : uploader
  const { sourceFile, ...request } = form
  if (!sourceFile) throw new Error('Choose the primary paper file.')
  const meetingId = Number(request.meetingId)
  if (!Number.isInteger(meetingId) || meetingId <= 0) throw new Error('Select a meeting for this board paper.')

  const title = String(request.title || '').trim()
  if (!title) throw new Error('Enter a paper title.')

  const paperType = String(request.paperType || '').trim().toUpperCase()
  if (!paperType) throw new Error('Select a paper type.')

  const filePath = String(await upload({ file: sourceFile, meetingId }) || '').trim()
  if (!filePath) throw new Error('The paper upload completed without returning a file path. Please try again.')

  const agendaItemId = Number(request.agendaItemId)
  const versionNumber = Number(request.versionNumber)
  const optionalText = value => String(value || '').trim() || null
  const checked = value => value === true || value === 'true'

  return {
    meetingId,
    agendaItemId: Number.isInteger(agendaItemId) && agendaItemId > 0 ? agendaItemId : null,
    paperType,
    title,
    referenceNumber: optionalText(request.referenceNumber),
    filePath,
    fileName: sourceFile.name,
    versionNumber: Number.isInteger(versionNumber) && versionNumber > 0 ? versionNumber : 1,
    requiresApproval: checked(request.requiresApproval),
    isMainPaper: checked(request.isMainPaper),
    disclaimerMessage: optionalText(request.disclaimerMessage),
  }
}

export const downloadProtectedPaper = async ({ paper, userId, apiClient = api, downloader = downloadFile }) => {
  const { data: authorizedPath } = await apiClient.get(`/secure-files/papers/${paper.id}`, { params: { userId, action: 'DOWNLOAD', channel: 'WEB' } })
  await downloader(authorizedPath, paper.fileName || `${paper.title || 'board-paper'}.pdf`)
  await apiClient.post(`/pack-delivery/paper/${paper.id}/downloaded`)
}

export const fetchProtectedPaper = async ({ paperId, userId, action = 'VIEW', apiClient = api }) => {
  const { data: authorizedPath } = await apiClient.get(`/secure-files/papers/${paperId}`, {
    params: { userId, action, channel: 'WEB' },
  })
  const { data } = await apiClient.get(authorizedPath, { responseType: 'blob' })
  return data
}
