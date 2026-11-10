import { useEffect, useState } from 'react'
import { api, errorMessage } from '../../api/client'

export default function ContentVisibilityPage() {
  const [period, setPeriod] = useState(null)
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const load = async () => {
    const { data } = await api.get('/content-visibility')
    setPeriod(data)
    setStartDate(data.startDate || '')
    setEndDate(data.endDate || '')
  }
  useEffect(() => { load().catch(err => setError(errorMessage(err))) }, [])

  const save = async event => {
    event.preventDefault()
    setError('')
    setNotice('')
    if (startDate > endDate) return setError('The end date must be on or after the start date.')
    setBusy(true)
    try {
      await api.put('/content-visibility', { startDate, endDate })
      await load()
      setNotice('Meetings in this date range and their papers are now hidden from non-admin users.')
    } catch (err) { setError(errorMessage(err)) } finally { setBusy(false) }
  }

  const clear = async () => {
    setBusy(true)
    setError('')
    setNotice('')
    try {
      await api.delete('/content-visibility')
      await load()
      setNotice('Hidden date range cleared. Meetings and papers are visible again.')
    } catch (err) { setError(errorMessage(err)) } finally { setBusy(false) }
  }

  return <div className="page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Settings / Content visibility</span><h2>Content visibility</h2><p>Choose meeting dates to hide from members and secretaries. Papers belonging to those meetings are hidden too.</p></div></div>
    <section className="panel" style={{ padding: '1.5rem', maxWidth: 700 }}>
      <h3>Hidden meeting date range</h3>
      <p>{period?.startDate ? `Meetings dated ${period.startDate} through ${period.endDate} are hidden. The end date is included.` : 'No meeting dates are hidden.'}</p>
      <form onSubmit={save} className="form-grid">
        <label>From meeting date<input type="date" required value={startDate} onChange={event => setStartDate(event.target.value)} /></label>
        <label>Through meeting date<input type="date" required value={endDate} onChange={event => setEndDate(event.target.value)} /></label>
        {error && <div className="alert error full">{error}</div>}
        {notice && <div className="alert success full">{notice}</div>}
        <div className="form-actions full"><button className="primary" disabled={busy}>Save hidden range</button>{period?.startDate && <button type="button" className="secondary" disabled={busy} onClick={clear}>Clear range</button>}</div>
      </form>
    </section>
  </div>
}
