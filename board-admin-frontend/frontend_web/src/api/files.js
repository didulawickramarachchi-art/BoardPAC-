import { api } from './client'
import { FILE_ENDPOINTS } from './endpoints'
import { uploadedFilePath } from './response'

export const uploadFile = async ({ file, meetingId, paperId, onProgress }) => {
  const body = new FormData()
  body.append('file', file, file.name)
  if (meetingId != null) body.append('meetingId', meetingId)
  if (paperId != null) body.append('paperId', paperId)
  const { data } = await api.post(FILE_ENDPOINTS.upload, body, { onUploadProgress: onProgress })
  return uploadedFilePath(data)
}

export const downloadFile = async (url, fallbackName = 'document', config = {}) => {
  if (!url) throw new Error('A download URL is required.')
  const { data, headers } = await api.get(url, { ...config, responseType: 'blob' })
  const objectUrl = URL.createObjectURL(data)
  const anchor = document.createElement('a')
  anchor.href = objectUrl
  const disposition = headers?.['content-disposition'] || ''
  const encodedName = disposition.match(/filename\*=UTF-8''([^;]+)/i)?.[1]
  const plainName = disposition.match(/filename="?([^";]+)"?/i)?.[1]
  anchor.download = encodedName ? decodeURIComponent(encodedName) : plainName || fallbackName
  anchor.style.display = 'none'
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  window.setTimeout(() => URL.revokeObjectURL(objectUrl), 0)
}
