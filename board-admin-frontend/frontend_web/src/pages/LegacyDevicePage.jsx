import { useEffect, useState } from 'react'
import { api, errorMessage } from '../api/client'

export default function LegacyDevicePage() {
  const [devices, setDevices] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  useEffect(() => {
    let active = true
    api.get('/legacy-archive/devices')
      .then(({ data }) => { if (active) setDevices(data) })
      .catch(err => { if (active) setError(errorMessage(err)) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [])
  return <div className="page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Legacy devices</span><h2>Legacy devices</h2><p>Old BoardPAC device inventory. These records do not approve access to the new app.</p></div></div>
    {error && <div className="alert error" role="alert">{error}</div>}
    <section className="panel">{loading ? <p>Loading devices...</p> : <div className="table-wrap"><table><thead><tr><th>Old ID</th><th>Device ID</th><th>Type code</th><th>Status code</th><th>Version</th><th>OS</th><th>Description</th></tr></thead><tbody>{devices.map(device => <tr key={device.source_id}><td>{device.source_id}</td><td>{device.device_identifier || '—'}</td><td>{device.device_type_code ?? '—'}</td><td>{device.status_code ?? '—'}</td><td>{device.version || '—'}</td><td>{device.os_name || '—'}</td><td>{device.description || '—'}</td></tr>)}</tbody></table></div>}</section>
  </div>
}
