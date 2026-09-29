import { useEffect, useState } from 'react'
import { Download, Search } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { downloadFile } from '../../api/files'
import { collectionFrom, tableRowsFrom } from '../../api/response'
import ResourcePage from '../../pages/ResourcePage'
import { meetingHistoryParams, pagedReportParams } from './reportParams'

const display = value => value == null || value === '' ? '-' : typeof value === 'object' ? JSON.stringify(value) : String(value)
function DataTable({ rows }) { const keys = Object.keys(rows[0] || {}).filter(key => key !== 'papers').slice(0,8); return <div className="table-wrap"><table><thead><tr>{keys.map(key => <th key={key}>{key.replace(/([A-Z])/g,' $1')}</th>)}</tr></thead><tbody>{rows.map((row,index) => <tr key={row.id ?? index}>{keys.map(key => <td key={key}>{display(row[key])}</td>)}</tr>)}</tbody></table></div> }

export function PagedReportPage({ kind }) {
  const audit = kind === 'audit'; const title = audit ? 'Audit Logs' : 'Login History'; const base = audit ? '/reports/audit-logs' : '/reports/login-history'
  const [rows,setRows] = useState([]); const [page,setPage] = useState(0); const [total,setTotal] = useState(0); const [search,setSearch] = useState(''); const [username,setUsername] = useState(''); const [error,setError] = useState(''); const [loading,setLoading] = useState(true)
  const load = async () => { setLoading(true); setError(''); try { const { data } = await api.get(`${base}/paged`, { params: pagedReportParams({ page, username }) }); setRows(data.content || []); setTotal(data.totalPages || 0) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }
  useEffect(() => { load() }, [page, username])
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Reports / {title}</span><h2>{title}</h2><p>{audit ? 'Review recorded administrative actions.' : 'Review authentication activity and outcomes.'}</p></div><button className="secondary" onClick={() => downloadFile(`${base}/export`, `${audit ? 'audit-logs' : 'login-history'}.csv`)}><Download /> Export CSV</button></div>{error && <div className="alert error">{error}</div>}<section className="panel"><form className="toolbar" onSubmit={event => { event.preventDefault(); setPage(0); setUsername(search) }}><label className="search"><Search /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Filter by username..." /></label><button className="primary">Apply</button></form>{loading ? <div className="state compact"><span className="spinner" /></div> : <DataTable rows={rows} />}<div className="pagination"><button className="secondary" disabled={!page} onClick={() => setPage(value => value - 1)}>Previous</button><span>Page {page + 1} of {Math.max(total,1)}</span><button className="secondary" disabled={page + 1 >= total} onClick={() => setPage(value => value + 1)}>Next</button></div></section></div>
}

export function MeetingHistoryPage() {
  const [categories,setCategories] = useState([]); const [subcategories,setSubcategories] = useState([]); const [filters,setFilters] = useState({ categoryId:'',subcategoryId:'',from:'',to:'' }); const [rows,setRows] = useState([]); const [error,setError] = useState(''); const [loading,setLoading] = useState(false)
  useEffect(() => { Promise.all([api.get('/categories'),api.get('/subcategories')]).then(([a,b]) => { setCategories(collectionFrom(a.data)); setSubcategories(collectionFrom(b.data)) }).catch(err => setError(errorMessage(err))) }, [])
  const params = meetingHistoryParams(filters); const load = async event => { event?.preventDefault(); setLoading(true); setError(''); try { setRows(tableRowsFrom((await api.get('/meeting-history-report',{ params })).data)) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }
  useEffect(() => { load() }, [])
  const update = event => { const next = { ...filters, [event.target.name]: event.target.value }; if (event.target.name === 'categoryId') next.subcategoryId=''; setFilters(next) }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Reports / Meeting history</span><h2>Meeting History</h2><p>Filter historical meetings and export a board-ready PDF.</p></div><button className="secondary" onClick={() => downloadFile('/meeting-history-report/pdf','meeting-history-report.pdf',{ params })}><Download /> Export PDF</button></div>{error && <div className="alert error">{error}</div>}<section className="panel"><form className="report-filters" onSubmit={load}><select name="categoryId" value={filters.categoryId} onChange={update}><option value="">All categories</option>{categories.map(item => <option key={item.id} value={item.id}>{item.displayName || item.name}</option>)}</select><select name="subcategoryId" value={filters.subcategoryId} onChange={update}><option value="">All subcategories</option>{subcategories.filter(item => !filters.categoryId || Number(item.categoryId)===Number(filters.categoryId)).map(item => <option key={item.id} value={item.id}>{item.displayName || item.name}</option>)}</select><input type="date" name="from" value={filters.from} onChange={update} /><input type="date" name="to" value={filters.to} onChange={update} /><button className="primary">Apply</button></form>{loading ? <div className="state compact"><span className="spinner" /></div> : <DataTable rows={rows} />}</section></div>
}

export function PersonalActivityPage(){return <ResourcePage title="My Activity" description="Your recent activity across the board workspace." endpoint="/activity/me" />}

export function SnapshotReportPage({ type }) {
  const config = {
    category: ['User Category Report', 'Assigned categories and member roles.', '/admin-reports/user-category'],
    license: ['License Utilization', 'Allocated and available user licenses.', '/admin-reports/license-utilization'],
    approvals: ['Pending Approvals', 'Papers awaiting board decisions.', '/admin-reports/pending-approvals'],
  }[type]
  const [data,setData] = useState(null); const [error,setError] = useState(''); const [loading,setLoading] = useState(true)
  useEffect(() => { api.get(config[2]).then(response => setData(response.data)).catch(err => setError(errorMessage(err))).finally(() => setLoading(false)) }, [config[2]])
  const rows = tableRowsFrom(data); const metrics = data && !Array.isArray(data) ? Object.entries(data).filter(([,value]) => ['string','number','boolean'].includes(typeof value)) : []
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Reports / {config[0]}</span><h2>{config[0]}</h2><p>{config[1]}</p></div></div>{error && <div className="alert error">{error}</div>}{metrics.length > 0 && <div className="report-metrics">{metrics.map(([key,value]) => <section className="panel" key={key}><span>{key.replace(/([A-Z])/g,' $1')}</span><strong>{display(value)}</strong></section>)}</div>}<section className="panel">{loading ? <div className="state compact"><span className="spinner" /></div> : <DataTable rows={rows} />}</section></div>
}
