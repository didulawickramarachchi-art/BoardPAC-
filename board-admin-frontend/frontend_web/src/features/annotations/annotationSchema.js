export const WEB_ANNOTATION_TYPE = 'WEB_OVERLAY_V1'
export const SCHEMA = 'boardpac.web-annotation/v1'

export const clamp = value => Math.max(0, Math.min(1, Number(value) || 0))
export const normalizedPoint = (clientX, clientY, rect) => ({
  x: clamp((clientX - rect.left) / rect.width),
  y: clamp((clientY - rect.top) / rect.height),
})

export const annotationRequest = ({ paperId, userId, pageNumber, action = 'add', annotation, documentKey }) => ({
  paperId,
  userId,
  annotationType: WEB_ANNOTATION_TYPE,
  pageNumber,
  annotationDataJson: JSON.stringify({ schema: SCHEMA, action, documentKey, annotation }),
})

export const parseWebEvents = records => records
  .filter(record => record.annotationType === WEB_ANNOTATION_TYPE)
  .map(record => { try { return { ...record, data: JSON.parse(record.annotationDataJson) } } catch { return null } })
  .filter(event => event?.data?.schema === SCHEMA)

export const reduceWebEvents = records => {
  const current = new Map()
  for (const event of parseWebEvents(records)) {
    const annotation = event.data.annotation
    if (!annotation?.id) continue
    if (event.data.action === 'delete') current.delete(annotation.id)
    else current.set(annotation.id, { ...annotation, pageNumber: event.pageNumber, documentKey: event.data.documentKey })
  }
  return [...current.values()]
}
