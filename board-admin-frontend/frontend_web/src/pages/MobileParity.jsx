import { useEffect, useState } from 'react'
import { Link, Navigate, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Activity, ArrowRight, CalendarDays, CheckCircle2, FileText, History, KeyRound, LockKeyhole, MessageSquare, Settings, ShieldCheck, Upload, UserRound, Users } from 'lucide-react'
import ResourcePage from './ResourcePage'
import { api, errorMessage } from '../api/client'
import { useAuth } from '../state/AuthContext'

const reportItems = [
  ['Login History', 'View user login activity', '/reports/login-history', History],
  ['Audit Logs', 'Track system actions', '/reports/audit-logs', Activity],
  ['User Category Report', 'View assigned categories and roles', '/reports/user-category', Users],
  ['License Utilization', 'Monitor user license usage', '/reports/license-utilization', ShieldCheck],
  ['Pending Approvals', 'Review pending paper approvals', '/reports/pending-approvals', CheckCircle2],
]

const settingItems = [
  ['Meeting & Circular', 'MEETING_CIRCULAR', 'Manage meeting and circular settings', CalendarDays],
  ['Agenda', 'AGENDA', 'Configure agenda related settings', FileText],
  ['Paper', 'PAPER', 'Manage paper settings and rules', FileText],
  ['User Management', 'USER_MANAGEMENT', 'Control user management settings', Users],
  ['Comment', 'COMMENT', 'Manage comment permissions', MessageSquare],
  ['General', 'GENERAL', 'Update general system settings', Settings],
]

export function LandingPage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  useEffect(() => {
    const timer = window.setTimeout(() => navigate(user ? '/dashboard' : '/login', { replace: true }), 1800)
    return () => window.clearTimeout(timer)
  }, [navigate, user])
  return <div className="landing-page"><i className="landing-circle one" /><i className="landing-circle two" /><i className="landing-circle three" /><div className="landing-center"><div className="landing-logo"><img src="/assets/slpa_logo.png" alt="SLPA" /></div><b>BOARDPACK</b><span className="spinner" /></div></div>
}

function TileHub({ title, subtitle, items }) {
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / {title}</span><h2>{title}</h2><p>{subtitle}</p></div></div>
    <div className="mobile-tile-grid">{items.map(([name, detail, path, Icon]) => <Link className="mobile-tile" to={path} key={name}><span className="mobile-tile-icon"><Icon /></span><span><b>{name}</b><small>{detail}</small></span><span className="mobile-tile-arrow"><ArrowRight /></span></Link>)}</div>
  </div>
}

export function ReportsHome() {
  const { role } = useAuth()
  if (role !== 'ADMIN') return <Navigate to="/dashboard" />
  return <TileHub title="Reports" subtitle="System activity, governance, and utilization reports." items={reportItems} />
}

export function ReportView({ type }) {
  const config = {
    login: ['Login History', 'View user login activity.', '/reports/login-history'],
    audit: ['Audit Logs', 'Track actions performed throughout the system.', '/reports/audit-logs'],
    category: ['User Category Report', 'Assigned categories and member roles.', '/admin-reports/user-category'],
    license: ['License Utilization', 'Monitor allocated and available user licenses.', '/admin-reports/license-utilization'],
    approvals: ['Pending Approvals', 'Papers awaiting board decisions.', '/admin-reports/pending-approvals'],
  }[type]
  return <ResourcePage title={config[0]} description={config[1]} endpoint={config[2]} />
}

export function SettingsHome() {
  const { role } = useAuth()
  if (role !== 'ADMIN') return <Navigate to="/dashboard" />
  return <TileHub title="Settings" subtitle="Configure the board management system." items={settingItems.map(([name, group, detail, Icon]) => [name, detail, `/settings/${group}`, Icon])} />
}

export function SettingGroup() {
  const { group } = useParams()
  const item = settingItems.find(entry => entry[1] === group)
  return <ResourcePage title={item?.[0] || 'Settings'} description={item?.[2] || 'System settings'} endpoint={`/settings/group/${group}`} createEndpoint="/settings" initialValues={{ settingGroup: group }} fields={[
    { name: 'settingKey', label: 'Setting key', required: true },
    { name: 'settingValue', label: 'Value', required: true },
    { name: 'settingGroup', type: 'hidden' },
  ]} />
}

export function ProfilePage() {
  const { user } = useAuth()
  const [file, setFile] = useState(null)
  const [preview, setPreview] = useState('')
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  useEffect(() => () => preview && URL.revokeObjectURL(preview), [preview])
  const choose = event => { const next = event.target.files?.[0]; if (next) { setFile(next); setPreview(URL.createObjectURL(next)) } }
  const upload = async () => {
    if (!file) return
    setBusy(true); setError('')
    const data = new FormData(); data.append('file', file)
    try { await api.post(`/users/${user.id}/profile-picture`, data); setNotice('Profile picture updated successfully.') }
    catch (err) { setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Profile</span><h2>Profile Picture</h2><p>Update the photo displayed with your board account.</p></div></div>
    <section className="panel profile-panel"><div className="profile-photo">{preview ? <img src={preview} alt="Selected profile" /> : <UserRound />}</div><h3>{user.displayName || user.username}</h3><p>{user.role}</p>
      {notice && <div className="alert success">{notice}</div>}{error && <div className="alert error">{error}</div>}
      <label className="secondary file-button"><Upload /> Choose image<input type="file" accept="image/png,image/jpeg" onChange={choose} /></label>
      <button className="primary" disabled={!file || busy} onClick={upload}>{busy ? 'Uploading…' : 'Save profile picture'}</button>
    </section>
  </div>
}

export function ResetPasswordPage() {
  const [params] = useSearchParams()
  const token = params.get('token') || ''
  const [form, setForm] = useState({ password: '', confirm: '' })
  const [error, setError] = useState('')
  const [done, setDone] = useState(false)
  const valid = /[A-Z]/.test(form.password) && /[a-z]/.test(form.password) && /\d/.test(form.password) && form.password.length >= 8
  const submit = async event => {
    event.preventDefault()
    if (!valid || form.password !== form.confirm) return setError('Use at least 8 characters with uppercase, lowercase, and a number. Passwords must match.')
    try { await api.post('/auth/reset-password', { token, newPassword: form.password }); setDone(true) }
    catch (err) { setError(errorMessage(err)) }
  }
  return <div className="standalone-page"><section className="reset-card">{done ? <><CheckCircle2 className="success-icon" /><h2>Password updated</h2><p>You can now sign in using your new password.</p><Link className="primary" to="/login">Back to Sign In</Link></> : !token ? <><KeyRound className="danger-icon" /><h2>Invalid password link</h2><p>Request a new password-change email from your profile settings.</p></> : <><LockKeyhole className="gold-icon" /><h2>Create a new password</h2><p>Use at least 8 characters with uppercase, lowercase, and a number.</p><form onSubmit={submit}><label>New password<input type="password" required value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></label><label>Confirm new password<input type="password" required value={form.confirm} onChange={e => setForm({ ...form, confirm: e.target.value })} /></label>{error && <div className="alert error">{error}</div>}<button className="primary">Update Password</button></form></>}</section></div>
}
