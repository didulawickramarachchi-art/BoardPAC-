import { useEffect, useState } from 'react'
import { Link, Navigate, useNavigate, useParams } from 'react-router-dom'
import { Activity, ArrowRight, CalendarDays, CheckCircle2, Eye, EyeOff, FileText, History, KeyRound, LockKeyhole, MailCheck, MessageSquare, Settings, ShieldCheck, Upload, UserRound, Users } from 'lucide-react'
import ResourcePage from './ResourcePage'
import { api, errorMessage } from '../api/client'
import { USER_ENDPOINTS } from '../api/endpoints'
import { useAuth } from '../state/AuthContext'
import { permissionsFor } from '../auth/permissions'
import { requestPasswordReset, resetPassword } from '../api/auth'
import { isValidEmail, readResetToken, removeResetTokenFromHistory, validateResetForm } from '../auth/passwordRecovery'

const reportItems = [
  ['My Activity', 'Review your recent board activity', '/reports/activity', Activity, 'canViewPersonalActivity'],
  ['Meeting History', 'Filter and export historical meetings', '/reports/meeting-history', CalendarDays, 'canViewMeetingHistory'],
  ['Login History', 'View user login activity', '/reports/login-history', History, 'canViewAdminReports'],
  ['Audit Logs', 'Track system actions', '/reports/audit-logs', Activity, 'canViewAdminReports'],
  ['User Category Report', 'View assigned categories and roles', '/reports/user-category', Users, 'canViewAdminReports'],
  ['License Utilization', 'Monitor user license usage', '/reports/license-utilization', ShieldCheck, 'canViewAdminReports'],
  ['Pending Approvals', 'Review pending paper approvals', '/reports/pending-approvals', CheckCircle2, 'canViewPendingApprovals'],
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
  const { user, initializing } = useAuth()
  useEffect(() => {
    if (initializing) return undefined
    const timer = window.setTimeout(() => navigate(user ? '/dashboard' : '/login', { replace: true }), 1800)
    return () => window.clearTimeout(timer)
  }, [initializing, navigate, user])
  return <div className="landing-page"><i className="landing-circle one" /><i className="landing-circle two" /><i className="landing-circle three" /><div className="landing-center"><div className="landing-logo"><img src="/assets/slpa_logo.png" alt="SLPA" /></div><b>BOARDPACK</b><span className="spinner" /></div></div>
}

function TileHub({ title, subtitle, items }) {
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / {title}</span><h2>{title}</h2><p>{subtitle}</p></div></div>
    <div className="mobile-tile-grid">{items.map(([name, detail, path, Icon]) => <Link className="mobile-tile" to={path} key={name}><span className="mobile-tile-icon"><Icon /></span><span><b>{name}</b><small>{detail}</small></span><span className="mobile-tile-arrow"><ArrowRight /></span></Link>)}</div>
  </div>
}

export function ReportsHome() {
  const { user } = useAuth()
  const access = permissionsFor(user)
  if (!access.canViewReports) return <Navigate to="/dashboard" />
  return <TileHub title="Reports" subtitle="System activity, governance, and utilization reports." items={reportItems.filter(item => access[item[4]])} />
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
  const [count, setCount] = useState(null)
  useEffect(() => { api.get('/settings').then(({ data }) => setCount(Array.isArray(data) ? data.length : 0)).catch(() => setCount(null)) }, [])
  if (role !== 'ADMIN') return <Navigate to="/dashboard" />
  return <TileHub title="Settings" subtitle={`Configure the board management system${count == null ? '.' : ` (${count} active settings).`}`} items={settingItems.map(([name, group, detail, Icon]) => [name, detail, `/settings/${group}`, Icon])} />
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
  const { user, refreshUser } = useAuth()
  const [file, setFile] = useState(null)
  const [preview, setPreview] = useState('')
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  useEffect(() => () => preview && URL.revokeObjectURL(preview), [preview])
  const choose = event => {
    const next = event.target.files?.[0]
    if (!next) return
    if (!['image/png', 'image/jpeg'].includes(next.type) || next.size > 5 * 1024 * 1024) {
      setError('Choose a PNG or JPEG image no larger than 5 MB.')
      return
    }
    setError(''); setFile(next); setPreview(URL.createObjectURL(next))
  }
  const upload = async () => {
    if (!file) return
    setBusy(true); setError('')
    const data = new FormData(); data.append('file', file)
    try { await api.post(USER_ENDPOINTS.profilePicture, data); await refreshUser(); setFile(null); setNotice('Profile picture updated successfully.') }
    catch (err) { setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  const updateTwoFactor = async event => {
    const enabled = event.target.checked
    setBusy(true); setError('')
    try { await api.put(USER_ENDPOINTS.twoFactor, { enabled }); await refreshUser(); setNotice(`Two-step authentication ${enabled ? 'enabled' : 'disabled'}.`) }
    catch (err) { setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  return <div className="page"><div className="page-heading"><div><span className="breadcrumb">Home / Profile</span><h2>Profile</h2><p>Manage your photo and account security.</p></div></div>
    <section className="panel profile-panel"><div className="profile-photo">{preview || user.profilePictureUrl ? <img src={preview || user.profilePictureUrl} alt="Profile" /> : <UserRound />}</div><h3>{user.displayName || user.username}</h3><p>{user.role}</p>
      {notice && <div className="alert success">{notice}</div>}{error && <div className="alert error">{error}</div>}
      <label className="secondary file-button"><Upload /> Choose image<input type="file" accept="image/png,image/jpeg" onChange={choose} /></label>
      <button className="primary" disabled={!file || busy} onClick={upload}>{busy ? 'Uploading…' : 'Save profile picture'}</button>
      <label><input type="checkbox" checked={Boolean(user.twoStepEnabled)} disabled={busy} onChange={updateTwoFactor} /> Two-step authentication</label>
    </section>
  </div>
}

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [done, setDone] = useState(false)
  const submit = async event => {
    event.preventDefault()
    if (busy) return
    if (!isValidEmail(email)) return setError('Enter a valid email address.')
    setBusy(true); setError('')
    try { await requestPasswordReset(email.trim()); setDone(true) }
    catch (err) { setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  return <div className="standalone-page"><section className="reset-card">{done ? <><MailCheck className="success-icon" /><h2>Check your email</h2><p>If the email is registered, a password-change link has been sent.</p><Link className="primary" to="/login">Back to sign in</Link></> : <><KeyRound className="gold-icon" /><h2>Forgot password?</h2><p>Enter your board email address to request a secure password-change link.</p><form onSubmit={submit}><label>Email address<input autoFocus type="email" autoComplete="email" maxLength="254" required value={email} onChange={event => setEmail(event.target.value)} /></label>{error && <div className="alert error">{error}</div>}<button className="primary" disabled={busy}>{busy ? 'Sending…' : 'Send reset link'}</button><Link className="text-button recovery-link" to="/login">Back to sign in</Link></form></>}</section></div>
}

export function ResetPasswordPage() {
  const [token] = useState(() => readResetToken(window.location.search))
  const [form, setForm] = useState({ password: '', confirm: '' })
  const [show, setShow] = useState({ password: false, confirm: false })
  const [error, setError] = useState('')
  const [rejected, setRejected] = useState(false)
  const [busy, setBusy] = useState(false)
  const [done, setDone] = useState(false)
  useEffect(() => { removeResetTokenFromHistory(window.location, window.history) }, [])
  const submit = async event => {
    event.preventDefault()
    if (busy) return
    const validationError = validateResetForm(form.password, form.confirm)
    if (validationError) return setError(validationError)
    setBusy(true); setError(''); setRejected(false)
    try { await resetPassword(token, form.password); setDone(true); setForm({ password: '', confirm: '' }) }
    catch (err) { setRejected([400, 404, 410].includes(err.response?.status)); setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  if (done) return <div className="standalone-page"><section className="reset-card"><CheckCircle2 className="success-icon" /><h2>Password updated</h2><p>Your existing sessions have been closed. Sign in with your new password.</p><Link className="primary" to="/login">Continue to sign in</Link></section></div>
  if (!token) return <div className="standalone-page"><section className="reset-card"><KeyRound className="danger-icon" /><h2>Invalid password link</h2><p>This link does not include a reset token. Request a new password-change email.</p><Link className="primary" to="/forgot-password">Request another link</Link></section></div>
  return <div className="standalone-page"><section className="reset-card"><LockKeyhole className="gold-icon" /><h2>Create a new password</h2><p>Use 8–128 characters with uppercase, lowercase, and a number.</p><form onSubmit={submit}><label>New password<div className="password"><input type={show.password ? 'text' : 'password'} autoComplete="new-password" minLength="8" maxLength="128" required value={form.password} onChange={event => setForm({ ...form, password: event.target.value })} /><button type="button" aria-label={show.password ? 'Hide new password' : 'Show new password'} onClick={() => setShow(current => ({ ...current, password: !current.password }))}>{show.password ? <EyeOff /> : <Eye />}</button></div></label><label>Confirm new password<div className="password"><input type={show.confirm ? 'text' : 'password'} autoComplete="new-password" minLength="8" maxLength="128" required value={form.confirm} onChange={event => setForm({ ...form, confirm: event.target.value })} /><button type="button" aria-label={show.confirm ? 'Hide confirmation' : 'Show confirmation'} onClick={() => setShow(current => ({ ...current, confirm: !current.confirm }))}>{show.confirm ? <EyeOff /> : <Eye />}</button></div></label>{error && <div className="alert error">{error}</div>}{rejected && <Link className="text-button recovery-link" to="/forgot-password">Request another link</Link>}<button className="primary" disabled={busy}>{busy ? 'Updating…' : 'Update password'}</button></form></section></div>
}
