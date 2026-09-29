import { useCallback, useEffect, useState } from 'react'
import { Plus } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'
import { rsvpPayload } from './meetingPayloads'

const statuses = ['ACCEPTED', 'DECLINED', 'TENTATIVE', 'CONCALL']

export default function ParticipantsPanel({ meetingId, user, canManage, meetingClosed }) {
  const [participants, setParticipants] = useState([])
  const [options, setOptions] = useState([])
  const [selectedUser, setSelectedUser] = useState('')
  const [rsvp, setRsvp] = useState({ status: 'ACCEPTED', reason: '' })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const load = useCallback(async () => { setLoading(true); setError(''); try { const responses = await Promise.all([api.get(`/meetings/${meetingId}/participants`), ...(canManage ? [api.get(`/meetings/${meetingId}/participant-options`)] : [])]); setParticipants(collectionFrom(responses[0].data)); setOptions(canManage ? collectionFrom(responses[1].data) : []) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [canManage, meetingId])
  useEffect(() => { load() }, [load])
  const mutate = async (key, operation, message) => { setSaving(key); setError(''); try { await operation(); setNotice(message); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving('') } }
  const add = event => { event.preventDefault(); mutate('add', () => api.post('/meetings/participants', { meetingId, userId: Number(selectedUser), displaySequence: participants.length }), 'Participant added.').then(() => setSelectedUser('')) }
  const update = (participant, participantStatus) => { const reason = ['DECLINED','TENTATIVE'].includes(participantStatus) ? window.prompt('Optional reason') : ''; if (reason == null) return; mutate(`status-${participant.id}`, () => api.put('/meetings/participants/status', { meetingId, userId: participant.userId, ...rsvpPayload(participantStatus, reason) }), 'Participant status updated.') }
  const submitRsvp = event => { event.preventDefault(); mutate('rsvp', () => api.put(`/meetings/${meetingId}/rsvp`, rsvpPayload(rsvp.status, rsvp.reason)), 'Your RSVP has been saved.') }
  const current = participants.find(participant => Number(participant.userId) === Number(user.id) || participant.username === user.username)
  if (loading) return <div className="page"><LoadingState label="Loading participants…" /></div>
  return <div className="page participants-panel">{error && <ErrorState error={error} retry={load} />}{notice && <div className="alert success">{notice}</div>}
    {!canManage && <section className="panel workflow-panel rsvp-panel"><div className="section-title"><div><h3>Your RSVP</h3><p>Current response: <b>{current?.participantStatus || 'PENDING'}</b></p></div></div><form className="compact-form" onSubmit={submitRsvp}><select value={rsvp.status} disabled={meetingClosed} onChange={event => setRsvp({ ...rsvp, status: event.target.value })}>{statuses.map(status => <option key={status}>{status}</option>)}</select><input placeholder="Optional reason" maxLength="500" disabled={meetingClosed} value={rsvp.reason} onChange={event => setRsvp({ ...rsvp, reason: event.target.value })} /><button className="primary" disabled={meetingClosed || saving === 'rsvp'}>Save RSVP</button></form>{meetingClosed && <p>This meeting is closed and no longer accepts responses.</p>}</section>}
    <section className="panel workflow-panel"><div className="section-title"><div><h3>Participants</h3><p>Invited members and their response status.</p></div></div>{canManage && <form className="compact-form" onSubmit={add}><select required value={selectedUser} onChange={event => setSelectedUser(event.target.value)}><option value="">Select participant</option>{options.filter(option => option.eligible && !option.participant).map(option => <option key={option.id} value={option.id}>{option.displayName || option.username}</option>)}</select><button className="primary" disabled={!selectedUser || saving === 'add'}><Plus />Add participant</button></form>}
      {!participants.length ? <EmptyState title="No participants" /> : <div className="workflow-list">{participants.map(participant => <article key={participant.id}><div><b>{participant.displayName || participant.username}</b><small>{participant.statusReason || 'No response reason'}</small></div><span className={`badge ${String(participant.participantStatus).toLowerCase()}`}>{participant.participantStatus}</span>{canManage && !meetingClosed && <select aria-label={`Status for ${participant.username}`} value={participant.participantStatus} disabled={Boolean(saving)} onChange={event => update(participant, event.target.value)}>{['PENDING', ...statuses].map(status => <option key={status}>{status}</option>)}</select>}</article>)}</div>}
    </section>
  </div>
}
