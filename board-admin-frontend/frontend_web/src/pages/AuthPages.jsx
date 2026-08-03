import { useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { ArrowRight, Eye, EyeOff, ShieldCheck } from 'lucide-react'
import { errorMessage } from '../api/client'
import { useAuth } from '../state/AuthContext'

function AuthFrame({ children, title, subtitle }) {
  return <div className="auth-page">
    <div className="auth-orb" />
    <section className="auth-panel">
      <div className="auth-identity">
        <img src="/assets/slpa_logo.png" alt="Sri Lanka Ports Authority logo" />
        <h1>SRI LANKA PORTS<br />AUTHORITY</h1>
        <span>Board Management System</span>
      </div>
      <div className="auth-card"><h2>{title}</h2><p>{subtitle}</p>{children}</div>
      <footer>© {new Date().getFullYear()} Sri Lanka Ports Authority</footer>
    </section>
  </div>
}

export function LoginPage() {
  const { user, login } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState({ username: '', password: '' })
  const [show, setShow] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  if (user) return <Navigate to="/dashboard" replace />
  const submit = async (event) => {
    event.preventDefault(); setBusy(true); setError('')
    try { const twoFactor = await login(form); navigate(twoFactor ? '/verify-2fa' : '/dashboard') }
    catch (err) { setError(errorMessage(err)) }
    finally { setBusy(false) }
  }
  return <AuthFrame title="Welcome Back" subtitle="Sign in to your account"><form onSubmit={submit}>
    <label>Username<input autoFocus required value={form.username} onChange={event => setForm({ ...form, username: event.target.value })} placeholder="User Name" /></label>
    <label>Password<div className="password"><input required type={show ? 'text' : 'password'} value={form.password} onChange={event => setForm({ ...form, password: event.target.value })} placeholder="••••••••" /><button type="button" aria-label={show ? 'Hide password' : 'Show password'} onClick={() => setShow(!show)}>{show ? <EyeOff /> : <Eye />}</button></div></label>
    {error && <div className="alert error">{error}</div>}
    <button className="primary wide" disabled={busy}>{busy ? 'Signing in…' : <>Sign In <ArrowRight /></>}</button>
  </form></AuthFrame>
}

export function VerifyPage() {
  const { challenge, verify, user } = useAuth()
  const navigate = useNavigate()
  const [code, setCode] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  if (user) return <Navigate to="/dashboard" />
  if (!challenge) return <Navigate to="/login" />
  const submit = async (event) => {
    event.preventDefault(); setBusy(true)
    try { await verify(code); navigate('/dashboard') }
    catch (err) { setError(errorMessage(err)); setBusy(false) }
  }
  return <AuthFrame title="Verify your identity" subtitle={`Enter the security code sent for ${challenge.username}.`}><form onSubmit={submit}>
    <div className="verify-icon"><ShieldCheck /></div>
    <label>Six-digit code<input className="otp" inputMode="numeric" pattern="[0-9]{6}" maxLength="6" required value={code} onChange={event => setCode(event.target.value.replace(/\D/g, ''))} placeholder="000000" /></label>
    {error && <div className="alert error">{error}</div>}
    <button className="primary wide" disabled={busy || code.length !== 6}>{busy ? 'Verifying…' : 'Verify and continue'}</button>
    <button type="button" className="text-button" onClick={() => navigate('/login')}>Back to sign in</button>
  </form></AuthFrame>
}
