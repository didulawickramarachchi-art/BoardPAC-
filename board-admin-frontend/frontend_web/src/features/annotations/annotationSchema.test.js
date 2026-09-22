import { describe, expect, it } from 'vitest'
import { annotationRequest, normalizedPoint, reduceWebEvents, SCHEMA, WEB_ANNOTATION_TYPE } from './annotationSchema'

describe('web annotation schema', () => {
  it('normalizes and clamps viewport coordinates', () => {
    const rect = { left: 100, top: 50, width: 400, height: 800 }
    expect(normalizedPoint(300, 450, rect)).toEqual({ x: .5, y: .5 })
    expect(normalizedPoint(0, 1000, rect)).toEqual({ x: 0, y: 1 })
  })
  it('serializes the API contract', () => {
    const request = annotationRequest({ paperId: 4, userId: 8, pageNumber: 2, documentKey: 'doc', annotation: { id: 'a', kind: 'ink' } })
    expect(request.annotationType).toBe(WEB_ANNOTATION_TYPE)
    expect(JSON.parse(request.annotationDataJson).schema).toBe(SCHEMA)
  })
  it('replays add and delete events', () => {
    const record = (action, id) => ({ annotationType: WEB_ANNOTATION_TYPE, pageNumber: 1, annotationDataJson: JSON.stringify({ schema: SCHEMA, action, documentKey: 'doc', annotation: { id, kind: 'ink' } }) })
    expect(reduceWebEvents([record('add', 'a'), record('add', 'b'), record('delete', 'a')]).map(item => item.id)).toEqual(['b'])
  })
})
