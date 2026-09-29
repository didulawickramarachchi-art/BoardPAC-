import { useEffect, useState } from 'react'
import { Eye, KeyRound, LockKeyhole, Pencil, Plus, Power, RefreshCw, Search, Trash2, UnlockKeyhole, X } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { accessProfilesForRole, prepareUserPayload } from './userPayloads'

const roles = ['ADMIN', 'SECRETARY', 'MEMBER']
const boardTypes = ['MEMBER', 'ORGANIZER', 'SUPPORT_TEAM']
const createFields = ['username', 'password', 'firstName', 'lastName', 'boardEmail', 'role', 'boardType', 'accessProfile']
const editFields = ['firstName', 'lastName', 'displayName', 'boardEmail', 'mobileNumber', 'jobTitle', 'profilePictureUrl', 'twoStepEnabled', 'role', 'boardType', 'accessProfile']
const label = value => value.replace(/([A-Z])/g, ' $1').replace(/^./, letter => letter.toUpperCase())

function UserForm({ mode, initial = {}, onClose, onSaved }) {
  const fields = mode === 'create' ? createFields : editFields
  const [form, setForm] = useState(() => Object.fromEntries(fields.map(key => [key, initial[key] ?? (key === 'twoStepEnabled' ? false : '')])))
  const [busy, setBusy] = useState(false); const [error, setError] = useState('')
  const submit = async event => {
    event.preventDefault(); setBusy(true); setError('')
    try { const payload=prepareUserPayload(form); mode === 'create' ? await api.post('/users', payload) : await api.put(`/users/${initial.id}`, payload); onSaved() }
    catch (err) { setError(errorMessage(err)) } finally { setBusy(false) }
  }
  const control = key => {
    if (key === 'twoStepEnabled') return <input type="checkbox" checked={Boolean(form[key])} onChange={event => setForm({ ...form, [key]: event.target.checked })} />
    const options = key === 'role' ? roles : key === 'boardType' ? boardTypes : key === 'accessProfile' ? accessProfilesForRole(form.role) : null
    if (options) return <select required value={form[key]} onChange={event => {const value=event.target.value;setForm(current=>({...current,[key]:value,...(key==='role'&&!accessProfilesForRole(value).includes(current.accessProfile)?{accessProfile:''}:{})}))}}><option value="">Select...</option>{options.map(option => <option key={option} value={option}>{option.replaceAll('_', ' ')}</option>)}</select>
    return <input type={key === 'password' ? 'password' : key.toLowerCase().includes('email') ? 'email' : 'text'} required={createFields.includes(key)} value={form[key]} onChange={event => setForm({ ...form, [key]: event.target.value })} />
  }
  return <div className="modal-backdrop"><section className="modal admin-modal" role="dialog" aria-modal="true"><div className="modal-head"><div><h3>{mode === 'create' ? 'Add user' : `Edit ${initial.username}`}</h3><p>{mode === 'create' ? 'Create the account first; profile details can be added afterward.' : 'Update account profile and access details.'}</p></div><button className="icon-button" onClick={onClose}><X /></button></div><form className="form-grid" onSubmit={submit}>{fields.map(key => <label key={key}>{label(key)}{control(key)}</label>)}{error && <div className="alert error full">{error}</div>}<div className="form-actions full"><button type="button" className="secondary" onClick={onClose}>Cancel</button><button className="primary" disabled={busy}>{busy ? 'Saving...' : 'Save user'}</button></div></form></section></div>
}

export default function UsersPage() {
  const [rows, setRows] = useState([]); const [page, setPage] = useState(0); const [totalPages, setTotalPages] = useState(0)
  const [search, setSearch] = useState(''); const [query, setQuery] = useState(''); const [status, setStatus] = useState('')
  const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [notice, setNotice] = useState(''); const [modal, setModal] = useState(null)
  const load = async () => { setLoading(true); setError(''); try { const { data } = await api.get('/users/paged', { params: { page, size: 10, search: query || undefined, status: status || undefined } }); setRows(data.content || []); setTotalPages(data.totalPages || 0) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }
  useEffect(() => { load() }, [page, query, status])
  const run = async (path, message) => { setError(''); try { await api.put(path); setNotice(message); await load() } catch (err) { setError(errorMessage(err)) } }
  const remove = async user => { if (window.prompt(`Type ${user.username} to permanently delete this account.`) !== user.username) return; try { await api.delete(`/users/${user.id}`); setNotice('User deleted.'); await load() } catch (err) { setError(errorMessage(err)) } }
  const details = async user => { try { setModal({ mode: 'detail', user: (await api.get(`/users/${user.id}`)).data }) } catch (err) { setError(errorMessage(err)) } }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Users</span><h2>Users</h2><p>Manage accounts, access profiles, status, and security.</p></div><button className="primary" onClick={() => setModal({ mode: 'create' })}><Plus /> Add user</button></div>
    {notice && <div className="alert success">{notice}</div>}{error && <div className="alert error">{error}</div>}
    <section className="panel"><form className="toolbar" onSubmit={event => { event.preventDefault(); setPage(0); setQuery(search.trim()) }}><label className="search"><Search /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Search users..." /></label><select value={status} onChange={event => { setPage(0); setStatus(event.target.value) }}><option value="">All statuses</option>{['ACTIVE','DEACTIVATED','LOCKED','DELETED'].map(value => <option key={value} value={value}>{value}</option>)}</select><button className="secondary">Search</button><button type="button" className="icon-button bordered" onClick={load}><RefreshCw /></button></form>
      <div className="table-wrap"><table><thead><tr><th>Username</th><th>Name</th><th>Email</th><th>Role</th><th>Profile</th><th>Status</th><th>Actions</th></tr></thead><tbody>{rows.map(user => <tr key={user.id}><td><b>{user.username}</b></td><td>{user.displayName || `${user.firstName || ''} ${user.lastName || ''}`}</td><td>{user.boardEmail}</td><td>{user.role}</td><td>{user.accessProfile?.replaceAll('_',' ')}</td><td><span className={`badge ${String(user.status).toLowerCase()}`}>{user.status}</span></td><td><div className="row-actions"><button title="View" onClick={() => details(user)}><Eye /></button><button title="Edit" onClick={() => setModal({ mode: 'edit', user })}><Pencil /></button><button title="Activate" onClick={() => run(`/users/${user.id}/activate`, 'User activated.')}><Power /></button><button title="Deactivate" onClick={() => run(`/users/${user.id}/deactivate`, 'User deactivated.')}><Power /></button><button title="Lock" onClick={() => run(`/users/${user.id}/lock`, 'User locked.')}><LockKeyhole /></button><button title="Unlock" onClick={() => run(`/users/${user.id}/unlock`, 'User unlocked.')}><UnlockKeyhole /></button><button title="Reset password" onClick={() => window.confirm('Reset this user password?') && run(`/users/${user.id}/reset-password`, 'Password reset requested.')}><KeyRound /></button><button title="Delete" onClick={() => remove(user)}><Trash2 /></button></div></td></tr>)}</tbody></table></div>
      {loading && <div className="state compact"><span className="spinner" /></div>}{!loading && rows.length === 0 && <div className="state compact"><h3>No users found</h3></div>}<div className="pagination"><button className="secondary" disabled={page === 0} onClick={() => setPage(value => value - 1)}>Previous</button><span>Page {page + 1} of {Math.max(totalPages, 1)}</span><button className="secondary" disabled={page + 1 >= totalPages} onClick={() => setPage(value => value + 1)}>Next</button></div>
    </section>
    {modal?.mode === 'detail' && <div className="modal-backdrop"><section className="modal admin-modal"><div className="modal-head"><h3>{modal.user.displayName || modal.user.username}</h3><button className="icon-button" onClick={() => setModal(null)}><X /></button></div><dl className="detail-grid">{Object.entries(modal.user).filter(([, value]) => value != null && typeof value !== 'object').map(([key,value]) => <div key={key}><dt>{label(key)}</dt><dd>{typeof value === 'boolean' ? (value ? 'Yes' : 'No') : String(value)}</dd></div>)}</dl></section></div>}
    {['create','edit'].includes(modal?.mode) && <UserForm mode={modal.mode} initial={modal.user} onClose={() => setModal(null)} onSaved={() => { setModal(null); setNotice('User saved.'); load() }} />}
  </div>
}
