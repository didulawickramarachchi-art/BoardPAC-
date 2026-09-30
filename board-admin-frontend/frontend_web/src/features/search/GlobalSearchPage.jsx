import { useEffect, useMemo, useState } from 'react'
import { CalendarDays, FileText, Search, Users } from 'lucide-react'
import { Link, useSearchParams } from 'react-router-dom'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import { ErrorState, LoadingState, EmptyState } from '../../components/AsyncState'
import { useAuth } from '../../state/AuthContext'
import { meetingListEndpoint, permissionsFor } from '../../auth/permissions'

export default function GlobalSearchPage() {
  const [params, setParams] = useSearchParams(); const { user } = useAuth(); const [query, setQuery] = useState(params.get('q') || '')
  const [groups, setGroups] = useState([]); const [loading, setLoading] = useState(false); const [error, setError] = useState('')
  useEffect(() => { const term = params.get('q')?.trim(); if (!term) { setGroups([]); return } let active = true; setLoading(true); setError('')
    const access = permissionsFor(user)
    const sources = [
      ...(access.canViewMeetings ? [['Meetings', meetingListEndpoint(user), CalendarDays, item => `/meetings/${item.id}`]] : []),
      ...(access.canViewPapers ? [['Papers', '/papers', FileText, item => `/papers/${item.id}`]] : []),
      ...(access.canViewUsers ? [['Users', '/users', Users, () => '/users']] : []),
    ]
    Promise.allSettled(sources.map(async ([name, endpoint, Icon, link]) => ({ name, Icon, link, rows: collectionFrom((await api.get(endpoint)).data).filter(row => JSON.stringify(row).toLowerCase().includes(term.toLowerCase())) })))
      .then(results => { if (!active) return; const found = results.filter(result => result.status === 'fulfilled').map(result => result.value); setGroups(found); const paperFailure = results.find((result, index) => sources[index][0] === 'Papers' && result.status === 'rejected'); if (paperFailure || !found.length) setError(errorMessage(paperFailure?.reason || results.find(result => result.status === 'rejected')?.reason)) })
      .finally(() => { if (active) setLoading(false) }); return () => { active = false }
  }, [params, user])
  const total = useMemo(() => groups.reduce((sum, group) => sum + group.rows.length, 0), [groups])
  const submit = event => { event.preventDefault(); setParams(query.trim() ? { q: query.trim() } : {}) }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Search</span><h2>Global search</h2><p>Search accessible meetings, papers and people.</p></div></div><form className="search-page-form" onSubmit={submit}><Search /><input autoFocus value={query} onChange={event => setQuery(event.target.value)} placeholder="Search BoardPAC…" /><button className="primary">Search</button></form>
    {loading ? <LoadingState label="Searching…" /> : error ? <ErrorState error={error} /> : params.get('q') && total === 0 ? <EmptyState title="No matching results" detail="Try another title, reference number or username." /> : <div className="search-results">{groups.filter(group => group.rows.length).map(({ name, Icon, link, rows }) => <section className="panel" key={name}><h3><Icon /> {name} <span>{rows.length}</span></h3>{rows.slice(0, 25).map((row, index) => <Link key={row.id || index} to={link(row)}><b>{row.title || row.displayName || row.username || `${name} #${row.id}`}</b><small>{row.referenceNumber || row.description || row.status || ''}</small></Link>)}</section>)}</div>}
  </div>
}
