const collectionKeys = ['content', 'items', 'notifications']

export const collectionFrom = data => {
  if (Array.isArray(data)) return data
  if (!data || typeof data !== 'object') return []
  for (const key of collectionKeys) {
    if (Array.isArray(data[key])) return data[key]
  }
  return []
}

export const tableRowsFrom = data => {
  const rows = collectionFrom(data)
  if (rows.length || Array.isArray(data)) return rows
  return data && typeof data === 'object' ? [data] : []
}

export const uploadedFilePath = data => {
  if (typeof data === 'string') return data.trim()
  if (!data || typeof data !== 'object') return ''
  for (const key of ['filePath', 'fileUrl', 'url', 'path', 'publicUrl']) {
    if (data[key] != null && String(data[key]).trim()) return String(data[key]).trim()
  }
  return ''
}

export const validationMessages = data => {
  if (!data?.validationErrors || typeof data.validationErrors !== 'object') return []
  return Object.entries(data.validationErrors).map(([field, message]) => `${field}: ${message}`)
}

