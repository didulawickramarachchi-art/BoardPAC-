import { useEffect, useState } from 'react'
import { Heart } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'

const targetId = item => Number(item.targetId || item.paperId || item.meetingId)

export default function FavoriteButton({ type, id }) {
  const [active, setActive] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => { let mounted = true; api.get('/favorites').then(({ data }) => { if (mounted) setActive(collectionFrom(data).some(item => String(item.favoriteType || item.type).toUpperCase() === type && targetId(item) === Number(id))) }).catch(() => {}); return () => { mounted = false } }, [id, type])
  const toggle = async () => { setBusy(true); setError(''); try { if (active) await api.delete(`/favorites/${type}/${id}`); else await api.put(`/favorites/${type}/${id}`); setActive(value => !value) } catch (err) { setError(errorMessage(err)) } finally { setBusy(false) } }
  return <span className="favorite-control"><button type="button" className={`secondary ${active ? 'selected' : ''}`} disabled={busy} aria-pressed={active} onClick={toggle}><Heart />{active ? 'Saved' : 'Save'}</button>{error && <small role="alert">{error}</small>}</span>
}
