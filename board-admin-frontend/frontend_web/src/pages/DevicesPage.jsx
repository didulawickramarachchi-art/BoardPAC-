import { useCallback, useEffect, useMemo, useState } from 'react'
import { CheckCircle2, Laptop, RefreshCw, RotateCcw, ShieldCheck, ShieldX, Smartphone, Trash2 } from 'lucide-react'
import { api, errorMessage } from '../api/client'

const isPending = status => ['PENDING', 'REQUESTED', 'AWAITING_APPROVAL'].includes(String(status).toUpperCase())
const isRegistered = status => ['APPROVED', 'ACTIVE'].includes(String(status).toUpperCase())
const isDeactivated = status => ['DEACTIVATED', 'INACTIVE'].includes(String(status).toUpperCase())
const isWiped = status => String(status).toUpperCase() === 'WIPED'
const DeviceIcon = ({ info = '' }) => /android|iphone|ios|mobile/i.test(info) ? <Smartphone /> : <Laptop />

function DeviceCard({ device, busy, onAction }) {
  return <article className="device-card">
    <div className="device-card-icon"><DeviceIcon info={device.deviceInfo} /></div>
    <div className="device-card-body">
      <div className="device-card-title"><strong>{device.deviceInfo || 'Unknown device'}</strong><span className={`badge ${String(device.status).toLowerCase()}`}>{device.status || 'UNKNOWN'}</span></div>
      <p>{device.deviceId}</p>
      <div className="device-meta"><span><b>User</b>{device.username || 'Unassigned'}</span><span><b>BoardPAC</b>{device.boardPacVersion || '—'}</span><span><b>OS</b>{device.osVersion || '—'}</span></div>
    </div>
    <div className="device-actions">
      {isPending(device.status) && <button className="primary" disabled={busy} onClick={() => onAction(device, 'approve')}><CheckCircle2 /> Approve</button>}
      {isRegistered(device.status) && <button className="secondary" disabled={busy} onClick={() => onAction(device, 'deactivate')}><ShieldX /> Deactivate</button>}
      {isDeactivated(device.status) && <button className="secondary" disabled={busy} onClick={() => onAction(device, 'activate')}><RotateCcw /> Activate</button>}
      {!isWiped(device.status) && <button className="device-danger" disabled={busy} onClick={() => onAction(device, 'wipe')}><Trash2 /> Wipe</button>}
      {isWiped(device.status) && <button className="device-danger" disabled={busy} onClick={() => onAction(device, 'delete')}><Trash2 /> Delete</button>}
    </div>
  </article>
}

export default function DevicesPage() {
  const [devices, setDevices] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [busyId, setBusyId] = useState(null)
  const load = useCallback(async ({ quiet = false } = {}) => {
    if (!quiet) setLoading(true)
    setError('')
    try { const { data } = await api.get('/devices'); setDevices(Array.isArray(data) ? data : data.content || data.items || []) }
    catch (err) { setError(errorMessage(err)) }
    finally { if (!quiet) setLoading(false) }
  }, [])
  useEffect(() => {
    load()
    const timer = window.setInterval(() => load({ quiet: true }), 15000)
    return () => window.clearInterval(timer)
  }, [load])
  const pending = useMemo(() => devices.filter(device => isPending(device.status)), [devices])
  const registered = useMemo(() => devices.filter(device => !isPending(device.status)), [devices])
  const action = async (device, name) => {
    if (name === 'wipe' && !window.confirm(`Wipe ${device.deviceInfo || device.deviceId}?`)) return
    if (name === 'delete' && !window.confirm(`Permanently delete ${device.deviceInfo || device.deviceId}?`)) return
    setBusyId(device.id); setError('')
    try {
      if (name === 'delete') await api.delete(`/devices/${device.id}`)
      else await api.put(`/devices/${device.id}/${name}`)
      setNotice(name === 'approve' ? 'Device approved successfully.' : `Device ${name} completed successfully.`)
      await load({ quiet: true })
    } catch (err) { setError(errorMessage(err)) }
    finally { setBusyId(null) }
  }
  const section = (title, description, items, empty) => <section className="device-section">
    <div className="device-section-heading"><div><h3>{title}</h3><p>{description}</p></div><span>{items.length}</span></div>
    {items.length ? <div className="device-list">{items.map(device => <DeviceCard key={device.id} device={device} busy={busyId === device.id} onAction={action} />)}</div> : <div className="device-empty">{empty}</div>}
  </section>
  return <div className="page devices-page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Administration / Devices</span><h2>Device management</h2><p>Approve new requests and manage devices allowed to access BoardPAC.</p></div><button className="secondary" onClick={() => load()} disabled={loading}><RefreshCw /> Refresh</button></div>
    <div className="device-stats"><div><ShieldCheck /><span>Registered devices<strong>{registered.length}</strong></span></div><div><RefreshCw /><span>Pending approval<strong>{pending.length}</strong></span></div></div>
    {error && <div className="alert error">{error}</div>}
    {notice && <div className="alert success">{notice}<button className="text-button" onClick={() => setNotice('')}>Dismiss</button></div>}
    {loading ? <div className="state"><div className="spinner" /><h3>Loading devices…</h3></div> : <>{section('Pending approval', 'New devices remain blocked until an administrator approves them.', pending, 'No pending device requests.')}{section('Registered devices', 'Approved, deactivated and wiped device records.', registered, 'No registered devices.')}</>}
  </div>
}
