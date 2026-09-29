import { uploadFile } from '../../api/files'

export const orderedIdsAfterMove = (items, itemId, direction) => {
  const ids = [...items].sort((a, b) => (a.displayOrder ?? 0) - (b.displayOrder ?? 0)).map(item => item.id)
  const index = ids.indexOf(itemId)
  const target = index + direction
  if (index < 0 || target < 0 || target >= ids.length) return ids
  ;[ids[index], ids[target]] = [ids[target], ids[index]]
  return ids
}

export const rsvpPayload = (participantStatus, statusReason) => ({
  participantStatus,
  statusReason: statusReason.trim() || null,
})

export const actionStatusPayload = (status, completionNote = '') => ({
  status,
  completionNote: completionNote.trim() || null,
})

export const prepareMeetingPayload = async (form, optionsOrUploader = {}, uploader = uploadFile) => {
  const upload = typeof optionsOrUploader === 'function' ? optionsOrUploader : uploader
  const { imageFile, ...request } = form
  if (!imageFile) return request
  return { ...request, imageUrl: await upload({ file: imageFile }) }
}
