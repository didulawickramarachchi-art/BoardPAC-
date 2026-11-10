import { useEffect, useState } from 'react'
import { api, errorMessage } from '../../api/client'

const toLocal = value => {
  if (!value) return ''
  const date = new Date(value)
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 16)
}

export default function ContentVisibilityPage() {
  const [period, setPeriod] = useState(null)
  const [startAt, setStartAt] = useState('')
  const [endAt, setEndAt] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const load = async () => {
    const { data } = await api.get('/content-visibility')
    setPeriod(data)
    setStartAt(toLocal(data.startAt))
    setEndAt(toLocal(data.endAt))
  }
  useEffect(() => { load().catch(err => setError(errorMessage(err))) }, [])

  const save = async event => {
    event.preventDefault()
    setError('')
    setNotice('')
    if (new Date(startAt) >= new Date(endAt)) return setError('The end time must be after the start time.')
    setBusy(true)
    try {
      await api.put('/content-visibility', { startAt: new Date(startAt).toISOString(), endAt: new Date(endAt).toISOString() })
      await load()
      setNotice('Visibility period saved.')
    } catch (err) { setError(errorMessage(err)) } finally { setBusy(false) }
  }

  const clear = async () => {
    setBusy(true)
    setError('')
    setNotice('')
    try {
      await api.delete('/content-visibility')
      await load()
      setNotice('Visibility period cleared. Meetings and papers are available again.')
    } catch (err) { setError(errorMessage(err)) } finally { setBusy(false) }
  }

  return <div className="page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Settings / Content visibility</span><h2>Content visibility</h2><p>Hide meetings and papers from everyone except administrators during a scheduled period.</p></div></div>
    <section className="panel" style={{ padding: '1.5rem', maxWidth: 700 }}>
      <h3>Scheduled hide period</h3>
      <p>{period?.active ? 'Active now: meetings and papers are hidden.' : period?.startAt ? new Date(period.endAt) <= new Date() ? 'The period has ended.' : 'Scheduled: content remains visible until the start time.' : 'No hide period is scheduled.'}</p>
      <form onSubmit={save} className="form-grid">
        <label>Start time<input type="datetime-local" required value={startAt} onChange={event => setStartAt(event.target.value)} /></label>
        <label>End time<input type="datetime-local" required value={endAt} onChange={event => setEndAt(event.target.value)} /></label>
        {error && <div className="alert error full">{error}</div>}
        {notice && <div className="alert success full">{notice}</div>}
        <div className="form-actions full"><button className="primary" disabled={busy}>Save period</button>{period?.startAt && <button type="button" className="secondary" disabled={busy} onClick={clear}>Clear period</button>}</div>
      </form>
    </section>
  </div>
}
