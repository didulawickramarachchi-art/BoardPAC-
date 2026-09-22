import { useCallback, useEffect, useState } from 'react'
import { FileText, HeartOff, RefreshCw } from 'lucide-react'
import { Link } from 'react-router-dom'
import { api, errorMessage } from '../../api/client'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'

const rowsFrom = data => Array.isArray(data) ? data : data?.content || data?.items || []
const target = item => item.paperId || item.targetId || item.id

export default function FavoritesPage() {
  const [items, setItems] = useState([]); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [busy, setBusy] = useState(null)
  const load = useCallback(async () => { setLoading(true); setError(''); try { setItems(rowsFrom((await api.get('/favorites')).data)) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [])
  useEffect(() => { load() }, [load])
  const remove = async item => { const id = target(item); const type = item.favoriteType || item.type || 'PAPER'; setBusy(id); try { await api.delete(`/favorites/${type}/${id}`); setItems(current => current.filter(value => value !== item)) } catch (err) { setError(errorMessage(err)) } finally { setBusy(null) } }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Member library</span><h2>Member library</h2><p>Your saved meetings, papers and board resources.</p></div><button className="secondary" onClick={load}><RefreshCw /> Refresh</button></div>
    {loading ? <LoadingState label="Loading favorites…" /> : error ? <ErrorState error={error} retry={load} /> : items.length === 0 ? <EmptyState title="Your library is empty" detail="Use the favorite action on a paper or meeting to save it here." /> : <div className="card-list">{items.map((item, index) => { const id = target(item); const type = String(item.favoriteType || item.type || 'PAPER').toUpperCase(); return <article className="panel" key={item.id || `${type}-${id}-${index}`}><FileText /><div><h3>{item.title || item.targetTitle || `${type} #${id}`}</h3><p>{item.description || type}</p></div><Link className="secondary" to={type === 'MEETING' ? `/meetings/${id}` : `/papers/${id}`}>Open</Link><button className="icon-button bordered" disabled={busy === id} aria-label="Remove favorite" onClick={() => remove(item)}><HeartOff /></button></article> })}</div>}
  </div>
}
