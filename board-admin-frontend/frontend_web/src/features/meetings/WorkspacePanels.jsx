import { useCallback, useEffect, useState } from 'react'
import { CheckCircle2, Pencil, Plus, Trash2 } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'
import ResourcePage from '../../pages/ResourcePage'

const rowsFrom = data => Array.isArray(data) ? data : data?.content || data?.items || []

export function PrivateNotes({ meetingId }) {
  const [items, setItems] = useState([]); const [text, setText] = useState(''); const [editing, setEditing] = useState(null); const [loading, setLoading] = useState(true); const [saving, setSaving] = useState(false); const [error, setError] = useState('')
  const load = useCallback(async () => { setLoading(true); setError(''); try { setItems(rowsFrom((await api.get(`/meeting-workspace/${meetingId}/notes`)).data)) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [meetingId])
  useEffect(() => { load() }, [load])
  const submit = async event => { event.preventDefault(); if (!text.trim()) return; setSaving(true); setError(''); try { if (editing) await api.put(`/meeting-workspace/notes/${editing.id}`, { noteText: text.trim() }); else await api.post(`/meeting-workspace/${meetingId}/notes`, { noteText: text.trim() }); setText(''); setEditing(null); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving(false) } }
  const remove = async id => { if (!window.confirm('Delete this private note?')) return; try { await api.delete(`/meeting-workspace/notes/${id}`); await load() } catch (err) { setError(errorMessage(err)) } }
  return <div className="page"><section className="panel"><div className="section-title"><div><h3>Private meeting notes</h3><p>Notes in this area are stored in your meeting workspace.</p></div></div><form className="inline-compose" onSubmit={submit}><textarea aria-label="Private note" required value={text} onChange={event => setText(event.target.value)} placeholder="Write a private note…" /><div><button type="submit" className="primary" disabled={saving}><Plus />{editing ? 'Update note' : 'Add note'}</button>{editing && <button type="button" className="secondary" onClick={() => { setEditing(null); setText('') }}>Cancel</button>}</div></form>{error && <ErrorState error={error} retry={load} />}{loading ? <LoadingState label="Loading notes…" compact /> : !items.length ? <EmptyState title="No private notes" /> : <div className="note-list">{items.map(item => <article key={item.id}><p>{item.noteText || item.text}</p><div><button className="icon-button bordered" aria-label="Edit note" onClick={() => { setEditing(item); setText(item.noteText || item.text || '') }}><Pencil /></button><button className="icon-button bordered" aria-label="Delete note" onClick={() => remove(item.id)}><Trash2 /></button></div></article>)}</div>}</section></div>
}

export function MeetingMinutes({ meetingId }) {
  const [items, setItems] = useState([]); const [content, setContent] = useState(''); const [loading, setLoading] = useState(true); const [saving, setSaving] = useState(''); const [error, setError] = useState('')
  const load = useCallback(async () => { setLoading(true); try { setItems(rowsFrom((await api.get(`/meeting-workspace/${meetingId}/minutes`)).data)); setError('') } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [meetingId])
  useEffect(() => { load() }, [load])
  const create = async event => { event.preventDefault(); if (!content.trim()) return; setSaving('new'); try { await api.post(`/meeting-workspace/${meetingId}/minutes`, { content: content.trim() }); setContent(''); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving('') } }
  const transition = async (item, action) => { const reviewComment = action === 'reject' ? window.prompt('Reason for rejection') : null; if (action === 'reject' && reviewComment == null) return; setSaving(`${item.id}-${action}`); try { await api.put(`/meeting-workspace/minutes/${item.id}/${action}`, { reviewComment }); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving('') } }
  return <div className="page"><section className="panel"><div className="section-title"><div><h3>Meeting minutes</h3><p>Draft, submit and review the official record.</p></div></div><form className="inline-compose" onSubmit={create}><textarea required value={content} onChange={event => setContent(event.target.value)} placeholder="Draft meeting minutes…" /><button className="primary" disabled={saving === 'new'}><Plus />Create draft</button></form>{error && <ErrorState error={error} retry={load} />}{loading ? <LoadingState label="Loading minutes…" /> : !items.length ? <EmptyState title="No meeting minutes" /> : <div className="note-list">{items.map(item => <article key={item.id}><div><span className={`badge ${String(item.status).toLowerCase()}`}>{item.status || 'DRAFT'}</span><p>{item.content}</p>{item.reviewComment && <small>Review: {item.reviewComment}</small>}</div><div>{String(item.status).toUpperCase() === 'DRAFT' && <button className="secondary" onClick={() => transition(item, 'submit')}>Submit</button>}{String(item.status).toUpperCase() === 'SUBMITTED' && <><button className="primary" onClick={() => transition(item, 'approve')}><CheckCircle2 />Approve</button><button className="secondary" onClick={() => transition(item, 'reject')}>Reject</button></>}</div></article>)}</div>}</section></div>
}

export function ActionItems({ meetingId }) {
  return <ResourcePage title="Action Items" description="Assign and track follow-up work from this meeting." endpoint={`/meetings/${meetingId}/action-items`} createEndpoint={`/meetings/${meetingId}/action-items`} fields={[
    { name: 'title', label: 'Title', required: true }, { name: 'description', label: 'Description', type: 'textarea', full: true },
    { name: 'assigneeUserId', label: 'Assignee', optionsEndpoint: `/meetings/${meetingId}/participant-options`, optionLabel: 'displayName', required: true },
    { name: 'dueDate', label: 'Due date', type: 'date' },
  ]} actions={[
    { label: 'Start', method: 'put', path: row => `/meetings/${meetingId}/action-items/${row.id}/status`, data: { status: 'IN_PROGRESS', completionNote: null } },
    { label: 'Complete', method: 'put', path: row => `/meetings/${meetingId}/action-items/${row.id}/status`, data: { status: 'COMPLETED', completionNote: null } },
    { label: 'Delete', method: 'delete', path: row => `/meetings/${meetingId}/action-items/${row.id}`, confirm: 'Delete this action item?' },
  ]} />
}
