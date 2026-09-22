import { useEffect, useMemo, useState } from 'react'
import { CalendarDays, FileText, Search, Users } from 'lucide-react'
import { Link, useSearchParams } from 'react-router-dom'
import { api, errorMessage } from '../../api/client'
import { ErrorState, LoadingState, EmptyState } from '../../components/AsyncState'
import { useAuth } from '../../state/AuthContext'

const rowsFrom = data => Array.isArray(data) ? data : data?.content || data?.items || []

export default function GlobalSearchPage() {
  const [params, setParams] = useSearchParams(); const { role } = useAuth(); const [query, setQuery] = useState(params.get('q') || '')
  const [groups, setGroups] = useState([]); const [loading, setLoading] = useState(false); const [error, setError] = useState('')
  useEffect(() => { const term = params.get('q')?.trim(); if (!term) { setGroups([]); return } let active = true; setLoading(true); setError('')
    const sources = [['Meetings', '/meetings', CalendarDays, item => `/meetings/${item.id}`], ['Papers', '/papers', FileText, item => `/papers/${item.id}`], ...(role === 'ADMIN' ? [['Users', '/users', Users, () => '/users']] : [])]
    Promise.all(sources.map(async ([name, endpoint, Icon, link]) => ({ name, Icon, link, rows: rowsFrom((await api.get(endpoint)).data).filter(row => JSON.stringify(row).toLowerCase().includes(term.toLowerCase())) })))
      .then(result => { if (active) setGroups(result) }).catch(err => { if (active) setError(errorMessage(err)) }).finally(() => { if (active) setLoading(false) }); return () => { active = false }
  }, [params, role])
  const total = useMemo(() => groups.reduce((sum, group) => sum + group.rows.length, 0), [groups])
  const submit = event => { event.preventDefault(); setParams(query.trim() ? { q: query.trim() } : {}) }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Search</span><h2>Global search</h2><p>Search accessible meetings, papers and people.</p></div></div><form className="search-page-form" onSubmit={submit}><Search /><input autoFocus value={query} onChange={event => setQuery(event.target.value)} placeholder="Search BoardPAC…" /><button className="primary">Search</button></form>
    {loading ? <LoadingState label="Searching…" /> : error ? <ErrorState error={error} /> : params.get('q') && total === 0 ? <EmptyState title="No matching results" detail="Try another title, reference number or username." /> : <div className="search-results">{groups.filter(group => group.rows.length).map(({ name, Icon, link, rows }) => <section className="panel" key={name}><h3><Icon /> {name} <span>{rows.length}</span></h3>{rows.slice(0, 25).map((row, index) => <Link key={row.id || index} to={link(row)}><b>{row.title || row.displayName || row.username || `${name} #${row.id}`}</b><small>{row.referenceNumber || row.description || row.status || ''}</small></Link>)}</section>)}</div>}
  </div>
}
