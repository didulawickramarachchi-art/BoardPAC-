import { useEffect, useState } from 'react'
import { api, errorMessage } from '../api/client'

export default function LegacyAuditPage() {
  const [page, setPage] = useState(0)
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => {
    let active = true
    setLoading(true)
    setError('')
    api.get('/legacy-archive/audit-events', { params: { page } })
      .then(({ data }) => { if (active) setRows(data) })
      .catch(err => { if (active) setError(errorMessage(err)) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [page])
  return <div className="page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Legacy audit history</span><h2>Legacy audit history</h2><p>Old BoardPAC events for review. These records do not affect the new app's audit log.</p></div></div>
    {error && <div className="alert error" role="alert">{error}</div>}
    <section className="panel">
      {loading ? <p>Loading events...</p> : <div className="table-wrap"><table><thead><tr><th>Time</th><th>Source</th><th>Module</th><th>Action</th><th>User</th><th>Event</th></tr></thead><tbody>
        {rows.map(row => <tr key={`${row.source_kind}-${row.source_id}`}><td>{row.event_time || '—'}</td><td>{row.source_kind}</td><td>{row.module_name || '—'}</td><td>{row.action_name || '—'}</td><td>{row.username || '—'}</td><td>{row.event_text || row.description || '—'}</td></tr>)}
      </tbody></table></div>}
      <div className="modal-actions"><button type="button" className="secondary" disabled={page === 0} onClick={() => setPage(value => value - 1)}>Previous</button><span>Page {page + 1}</span><button type="button" className="secondary" disabled={rows.length < 100} onClick={() => setPage(value => value + 1)}>Next</button></div>
    </section>
  </div>
}
