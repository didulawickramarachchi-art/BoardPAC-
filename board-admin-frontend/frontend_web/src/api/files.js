import { api } from './client'

export const uploadFile = async ({ file, meetingId, paperId, onProgress }) => {
  const body = new FormData()
  body.append('file', file, file.name)
  if (meetingId != null) body.append('meetingId', meetingId)
  if (paperId != null) body.append('paperId', paperId)
  const { data } = await api.post('/files/upload', body, { onUploadProgress: onProgress })
  if (typeof data === 'string') return data
  return data?.filePath || data?.fileUrl || data?.url || data?.path || data?.publicUrl || ''
}

export const downloadFile = async (url, fallbackName = 'document') => {
  const { data } = await api.get(url, { responseType: 'blob' })
  const objectUrl = URL.createObjectURL(data)
  const anchor = document.createElement('a')
  anchor.href = objectUrl
  anchor.download = fallbackName
  anchor.click()
  URL.revokeObjectURL(objectUrl)
}
