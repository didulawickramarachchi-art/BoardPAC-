import { uploadFile } from '../../api/files'

export const prepareCategoryPayload = async (form, optionsOrUploader = {}, uploader = uploadFile) => {
  const upload = typeof optionsOrUploader === 'function' ? optionsOrUploader : uploader
  const { imageFile, ...payload } = form
  if (imageFile) payload.imageUrl = await upload({ file: imageFile })
  return payload
}

export const settingInputType = value => {
  if (/^(true|false)$/i.test(String(value))) return 'boolean'
  if (/^-?\d+(\.\d+)?$/.test(String(value))) return 'number'
  return 'text'
}

export const settingOptions = key => ({
  WATERMARK_TYPE: ['NONE', 'USER_NAME', 'EMAIL', 'USER_NAME_AND_EMAIL'],
})[key] || null
