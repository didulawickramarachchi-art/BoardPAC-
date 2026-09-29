import { useCallback, useEffect, useState } from 'react'
import { Heart, MessageCircle, Pencil, Send, Share2, ThumbsDown, ThumbsUp, Trash2 } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'
import { normalizeRole } from '../../auth/permissions'

const reactions = [['LIKE', ThumbsUp], ['LOVE', Heart], ['DISLIKE', ThumbsDown]]

export default function CommentsPanel({ kind, targetId, user, canComment = true }) {
  const endpoint = `/comments/${kind}/${targetId}`
  const [items, setItems] = useState([])
  const [people, setPeople] = useState([])
  const [text, setText] = useState('')
  const [visibility, setVisibility] = useState('ALL_PARTICIPANTS')
  const [selectedUserIds, setSelectedUserIds] = useState([])
  const [editing, setEditing] = useState(null)
  const [replying, setReplying] = useState(null)
  const [reply, setReply] = useState('')
  const [shareTargets, setShareTargets] = useState({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const secretary = normalizeRole(user.role) === 'SECRETARY'

  const load = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const peopleEndpoint = kind === 'meeting' ? `/meetings/${targetId}/participants` : secretary ? '/users' : null
      const responses = await Promise.all([api.get(endpoint), ...(peopleEndpoint ? [api.get(peopleEndpoint)] : [])])
      setItems(collectionFrom(responses[0].data))
      setPeople(peopleEndpoint ? collectionFrom(responses[1].data).map(person => ({ id: person.userId || person.id, label: person.displayName || person.username })) : [])
    } catch (err) { setError(errorMessage(err)) }
    finally { setLoading(false) }
  }, [endpoint, kind, secretary, targetId])
  useEffect(() => { load() }, [load])
  const payload = value => ({ [`${kind}Id`]: targetId, commentText: value, annotated: false, visibility, pageNumber: null, selectedUserIds: visibility === 'SELECTED_PARTICIPANTS' ? selectedUserIds : [] })
  const resetForm = () => { setText(''); setEditing(null); setVisibility('ALL_PARTICIPANTS'); setSelectedUserIds([]) }
  const submit = async event => { event.preventDefault(); if (!text.trim()) return; if (visibility === 'SELECTED_PARTICIPANTS' && !selectedUserIds.length) return setError('Select at least one participant.'); setSaving(true); setError(''); try { if (editing) await api.put(`/comments/${editing.id}`, payload(text.trim())); else await api.post('/comments', payload(text.trim())); resetForm(); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving(false) } }
  const remove = async item => { if (!window.confirm('Delete this comment?')) return; try { await api.delete(`/comments/${item.id}`); await load() } catch (err) { setError(errorMessage(err)) } }
  const react = async (item, reactionType) => { try { await api.post(`/comments/${item.id}/reaction`, { reactionType }); await load() } catch (err) { setError(errorMessage(err)) } }
  const sendReply = async item => { if (!reply.trim()) return; try { await api.post(`/comments/${item.id}/replies`, { message: reply.trim() }); setReply(''); setReplying(null); await load() } catch (err) { setError(errorMessage(err)) } }
  const share = async item => { const sharedToUserId = Number(shareTargets[item.id]); if (!sharedToUserId) return; try { await api.post('/comments/share', { commentId: item.id, sharedByUserId: user.id, sharedToUserId }); setNotice('Comment shared successfully.'); setShareTargets(current => ({ ...current, [item.id]: '' })) } catch (err) { setError(errorMessage(err)) } }
  const edit = item => { setEditing(item); setText(item.commentText); setVisibility(item.visibility || 'ALL_PARTICIPANTS'); setSelectedUserIds(item.selectedUserIds || []) }
  const toggleRecipient = id => setSelectedUserIds(current => current.includes(id) ? current.filter(value => value !== id) : [...current, id])

  return <div className="page"><section className="panel comments-panel"><div className="section-title"><div><h3>Comments</h3><p>Discuss this {kind} with authorized participants.</p></div></div>{canComment && <form className="comment-compose" onSubmit={submit}><textarea required value={text} onChange={event => setText(event.target.value)} placeholder="Write a comment…" /><div><select value={visibility} onChange={event => setVisibility(event.target.value)}><option value="ALL_PARTICIPANTS">All participants</option><option value="PRIVATE">Private</option>{people.length > 0 && <option value="SELECTED_PARTICIPANTS">Selected participants</option>}</select><button className="primary" disabled={saving}><Send />{editing ? 'Update' : 'Post comment'}</button>{editing && <button type="button" className="secondary" onClick={resetForm}>Cancel</button>}</div>{visibility === 'SELECTED_PARTICIPANTS' && <div className="recipient-picker">{people.filter(person => Number(person.id) !== Number(user.id)).map(person => <label key={person.id}><input type="checkbox" checked={selectedUserIds.includes(Number(person.id))} onChange={() => toggleRecipient(Number(person.id))} />{person.label}</label>)}</div>}</form>}{notice && <div className="alert success">{notice}</div>}{error && <ErrorState error={error} retry={load} />}{loading ? <LoadingState label="Loading comments…" /> : !items.length ? <EmptyState title="No comments yet" /> : <div className="comment-thread">{items.map(item => <article key={item.id}><header><b>{item.createdByUsername || 'User'}</b><small>{item.createdAt ? new Date(item.createdAt).toLocaleString() : ''}</small><span className="badge muted">{item.visibility || 'ALL_PARTICIPANTS'}</span></header><p>{item.commentText}</p><div className="comment-actions">{reactions.map(([type, Icon]) => <button onClick={() => react(item, type)} className={item.currentReaction === type ? 'selected' : ''} title={type} key={type}><Icon />{item.reactionCounts?.[type] || 0}</button>)}<button onClick={() => setReplying(replying === item.id ? null : item.id)}><MessageCircle />Reply</button>{item.ownedByCurrentUser && <><button onClick={() => edit(item)}><Pencil />Edit</button><button onClick={() => remove(item)}><Trash2 />Delete</button></>}</div>{secretary && <div className="comment-share"><select aria-label="Share comment with" value={shareTargets[item.id] || ''} onChange={event => setShareTargets(current => ({ ...current, [item.id]: event.target.value }))}><option value="">Share with user</option>{people.filter(person => Number(person.id) !== Number(user.id)).map(person => <option key={person.id} value={person.id}>{person.label}</option>)}</select><button className="secondary" disabled={!shareTargets[item.id]} onClick={() => share(item)}><Share2 />Share</button></div>}{(item.replies || []).map(value => <div className="comment-reply" key={value.id}><b>{value.createdByUsername || 'User'}</b><p>{value.message}</p></div>)}{replying === item.id && <div className="reply-compose"><input autoFocus value={reply} onChange={event => setReply(event.target.value)} placeholder="Write a reply…" /><button className="primary" onClick={() => sendReply(item)}>Reply</button></div>}</article>)}</div>}</section></div>
}
