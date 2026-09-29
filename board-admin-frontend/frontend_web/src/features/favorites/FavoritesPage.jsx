import { useCallback, useEffect, useState } from 'react'
import { Clock3, FileText, HeartOff, RefreshCw } from 'lucide-react'
import { Link } from 'react-router-dom'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'

const target = item => item.paperId || item.meetingId || item.targetId || item.id

export default function FavoritesPage() {
  const [tab, setTab] = useState('favorites')
  const [favorites, setFavorites] = useState([])
  const [recent, setRecent] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(null)
  const load = useCallback(async () => { setLoading(true); setError(''); try { const [saved, history] = await Promise.all([api.get('/favorites'), api.get('/paper-read-states/recent')]); setFavorites(collectionFrom(saved.data)); setRecent(collectionFrom(history.data)) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [])
  useEffect(() => { load() }, [load])
  const remove = async item => { const id = target(item); const type = String(item.favoriteType || item.type || 'PAPER').toUpperCase(); setBusy(id); try { await api.delete(`/favorites/${type}/${id}`); setFavorites(current => current.filter(value => value !== item)) } catch (err) { setError(errorMessage(err)) } finally { setBusy(null) } }
  const rows = tab === 'favorites' ? favorites : recent
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Member library</span><h2>Member library</h2><p>Saved items and recently opened board papers.</p></div><button className="secondary" onClick={load}><RefreshCw /> Refresh</button></div><div className="tabs library-tabs"><button className={tab === 'favorites' ? 'active' : ''} onClick={() => setTab('favorites')}>Favorites</button><button className={tab === 'recent' ? 'active' : ''} onClick={() => setTab('recent')}>Recent papers</button></div>
    {loading ? <LoadingState label="Loading library…" /> : error ? <ErrorState error={error} retry={load} /> : rows.length === 0 ? <EmptyState title={tab === 'favorites' ? 'Your library is empty' : 'No recently opened papers'} detail={tab === 'favorites' ? 'Use the save action on a paper or meeting.' : 'Papers will appear after you open them.'} /> : <div className="card-list">{rows.map((item, index) => { const id = target(item); const type = tab === 'recent' ? 'PAPER' : String(item.favoriteType || item.type || 'PAPER').toUpperCase(); return <article className="panel" key={item.id || `${type}-${id}-${index}`}><FileText /><div><h3>{item.title || item.targetTitle || `${type} #${id}`}</h3><p>{tab === 'recent' ? <><Clock3 /> {item.lastOpenedAt ? new Date(item.lastOpenedAt).toLocaleString() : 'Recently opened'}{item.lastPage ? ` · Page ${item.lastPage}${item.totalPages ? ` of ${item.totalPages}` : ''}` : ''}</> : item.description || type}</p></div><Link className="secondary" to={type === 'MEETING' ? `/meetings/${id}` : `/papers/${id}`}>Open</Link>{tab === 'favorites' && <button className="icon-button bordered" disabled={busy === id} aria-label="Remove favorite" onClick={() => remove(item)}><HeartOff /></button>}</article> })}</div>}
  </div>
}
