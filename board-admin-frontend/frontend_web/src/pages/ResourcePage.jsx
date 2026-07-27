import { useEffect, useMemo, useState } from 'react'
import { AlertTriangle, Inbox, MoreHorizontal, Pencil, Plus, RefreshCw, Search, Trash2 } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { api, errorMessage } from '../api/client'

const humanize = key => key.replace(/([A-Z])/g, ' $1').replace(/_/g, ' ').replace(/^./, c => c.toUpperCase())
const ignored = new Set(['password', 'annotationDataJson', 'backupJson'])
const display = value => typeof value === 'boolean' ? (value ? 'Yes' : 'No') : value == null || value === '' ? '—' : typeof value === 'object' ? JSON.stringify(value) : String(value)

function RemoteSelect({ field, form, update }) {
  const dependency = field.dependsOn ? form[field.dependsOn] : true
  const [options, setOptions] = useState([]); const [loading, setLoading] = useState(false); const [error, setError] = useState('')
  useEffect(() => {
    if (!dependency) { setOptions([]); return }
    let active = true; setLoading(true); setError('')
    const url = typeof field.optionsEndpoint === 'function' ? field.optionsEndpoint(form) : field.optionsEndpoint
    api.get(url).then(({ data }) => { if (active) setOptions((Array.isArray(data) ? data : data.content || data.items || []).filter(item => !field.filter || field.filter(item, form))) }).catch(err => { if (active) setError(errorMessage(err)) }).finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [field, dependency, form])
  const label = item => item[field.optionLabel || 'displayName'] || item.name || item.title || item.username || `#${item.id}`
  return <select required={field.required} disabled={!dependency || loading} value={form[field.name] ?? ''} onChange={e => update(field, e.target.value)}><option value="">{loading ? 'Loading…' : error ? 'Failed to load options' : field.placeholder || `Select ${field.label.toLowerCase()}…`}</option>{options.map(item => <option key={item[field.optionValue || 'id']} value={item[field.optionValue || 'id']}>{label(item)}</option>)}</select>
}

export default function ResourcePage({ title, description, endpoint, createEndpoint, fields = [], columns, actions = [], editable = false, deletable = false, initialValues = {}, rowLink }) {
  const navigate = useNavigate()
  const [rows, setRows] = useState([]); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [notice, setNotice] = useState('')
  const [search, setSearch] = useState(''); const [modal, setModal] = useState(false); const [editing, setEditing] = useState(null); const [form, setForm] = useState({}); const [saving, setSaving] = useState(false)
  const load = async () => { setLoading(true); setError(''); try { const { data } = await api.get(endpoint); setRows(Array.isArray(data) ? data : data.content || data.items || []) } catch (e) { setError(errorMessage(e)) } finally { setLoading(false) } }
  useEffect(() => { load() }, [endpoint])
  const filtered = useMemo(() => rows.filter(row => JSON.stringify(row).toLowerCase().includes(search.toLowerCase())), [rows, search])
  const keys = columns || Object.keys(rows[0] || {}).filter(k => !ignored.has(k)).slice(0, 7)
  const openCreate = () => { setEditing(null); setForm(initialValues); setModal(true) }
  const openEdit = row => { setEditing(row); setForm(Object.fromEntries(fields.map(f => [f.name, row[f.name] ?? '']))); setModal(true) }
  const submit = async e => { e.preventDefault(); setSaving(true); setError(''); try { editing ? await api.put(`${endpoint}/${editing.id}`, form) : await api.post(createEndpoint || endpoint, form); setModal(false); setEditing(null); setNotice('Record saved successfully.'); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving(false) } }
  const remove = async row => { if (!window.confirm(`Delete this ${title.replace(/s$/, '').toLowerCase()}?`)) return; try { await api.delete(`${endpoint}/${row.id}`); setNotice('Record deleted successfully.'); await load() } catch (err) { setError(errorMessage(err)) } }
  const runAction = async (action, row) => { if (action.confirm && !window.confirm(action.confirm)) return; setError(''); try { const response = action.run ? await action.run(row, load) : await api[action.method || 'post'](action.path(row)); setNotice(response?.data?.message || `${action.label} completed successfully.`); await load() } catch (err) { setError(errorMessage(err)) } }
  const allActions = [...actions, ...(editable ? [{ label: 'Edit', icon: <Pencil />, local: openEdit }] : []), ...(deletable ? [{ label: 'Delete', icon: <Trash2 />, local: remove }] : [])]
  const update = (field, value) => setForm(current => ({ ...current, [field.name]: field.type === 'number' ? (value === '' ? '' : Number(value)) : field.type === 'checkbox' ? value : value }))

  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / {title}</span><h2>{title}</h2><p>{description}</p></div>{createEndpoint && <button className="primary" onClick={openCreate}><Plus /> Add {title.replace(/s$/, '')}</button>}</div>
    {notice && <div className="alert success" role="status">{notice}<button className="text-button" onClick={() => setNotice('')}>Dismiss</button></div>}
    <section className="panel"><div className="toolbar"><label className="search"><Search /><input value={search} onChange={e => setSearch(e.target.value)} placeholder={`Search ${title.toLowerCase()}…`} /></label><button className="icon-button bordered" onClick={load} title="Refresh"><RefreshCw /></button><span className="result-count">{filtered.length} records</span></div>
      {loading ? <div className="state"><div className="spinner" /><h3>Loading {title.toLowerCase()}…</h3></div> : error ? <div className="state"><AlertTriangle /><h3>We couldn't load this page</h3><p>{error}</p><button className="secondary" onClick={load}>Try again</button></div> : filtered.length === 0 ? <div className="state"><Inbox /><h3>{search ? 'No matching results' : `No ${title.toLowerCase()} yet`}</h3><p>{search ? 'Try a different search term.' : 'New records will appear here.'}</p></div> : <div className="table-wrap"><table><thead><tr>{keys.map(k => <th key={k}>{humanize(k)}</th>)}{allActions.length > 0 && <th>Actions</th>}</tr></thead><tbody>{filtered.map((row, index) => <tr className={rowLink?'clickable-row':''} onClick={rowLink?()=>navigate(rowLink(row)):undefined} key={row.id || index}>{keys.map(k => <td key={k}>{typeof row[k] === 'boolean' ? <span className={`badge ${row[k] ? 'success' : 'muted'}`}>{display(row[k])}</span> : k.toLowerCase().includes('status') || k === 'level' ? <span className={`badge ${String(row[k]).toLowerCase()}`}>{display(row[k])}</span> : display(row[k])}</td>)}{allActions.length > 0 && <td onClick={e=>e.stopPropagation()}><div className="row-actions">{allActions.map(a => a.link ? <Link title={a.label} key={a.label} to={a.link(row)}>{a.icon || <MoreHorizontal />}</Link> : <button type="button" title={a.label} key={a.label} onClick={() => a.local ? a.local(row) : runAction(a, row)}>{a.icon || <MoreHorizontal />}</button>)}</div></td>}</tr>)}</tbody></table></div>}
    </section>
    {modal && <div className="modal-layer" role="dialog" aria-modal="true"><form className="modal" onSubmit={submit}><div><span className="eyebrow">{editing ? 'Edit record' : 'New record'}</span><h2>{editing ? 'Edit' : 'Add'} {title.replace(/s$/, '')}</h2><p>Complete the information below. Fields marked * are required.</p></div><div className="form-grid">{fields.filter(f=>f.type!=='hidden').map(f => <label key={f.name} className={f.full ? 'full' : ''}>{f.label}{f.optionsEndpoint ? <RemoteSelect field={f} form={form} update={(field,value) => { const next = {...form,[field.name]:Number(value)}; (field.clears || []).forEach(name => { next[name] = '' }); setForm(next) }} /> : f.type === 'select' ? <select required={f.required} value={form[f.name] || ''} onChange={e => update(f, e.target.value)}><option value="">Select…</option>{f.options.map(o => <option key={o} value={o}>{humanize(o)}</option>)}</select> : f.type === 'textarea' ? <textarea required={f.required} value={form[f.name] || ''} onChange={e => update(f, e.target.value)} /> : f.type === 'checkbox' ? <input type="checkbox" checked={Boolean(form[f.name])} onChange={e => update(f, e.target.checked)} /> : <input required={f.required} type={f.type || 'text'} value={form[f.name] ?? ''} onChange={e => update(f, e.target.value)} />}</label>)}</div><div className="modal-actions"><button type="button" className="secondary" onClick={() => { setModal(false); setEditing(null) }}>Cancel</button><button className="primary" disabled={saving}>{saving ? 'Saving…' : 'Save record'}</button></div></form></div>}
  </div>
}
