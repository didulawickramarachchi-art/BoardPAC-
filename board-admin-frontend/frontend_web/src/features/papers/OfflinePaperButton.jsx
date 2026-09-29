import { useEffect, useState } from 'react'
import { DownloadCloud, ExternalLink, Trash2 } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { getOfflinePaper, removeOfflinePaper, saveOfflinePaper } from './offlineStore'

export default function OfflinePaperButton({ paper, userId }) {
  const [saved,setSaved] = useState(null); const [busy,setBusy] = useState(false); const [error,setError] = useState('')
  useEffect(() => { getOfflinePaper(paper.id).then(setSaved).catch(() => {}) }, [paper.id])
  const keep = async () => { setBusy(true); setError(''); try { const { data: filePath } = await api.get(`/secure-files/papers/${paper.id}`, { params: { userId, action: 'DOWNLOAD', channel: 'WEB' } }); const { data: blob } = await api.get(filePath, { responseType: 'blob' }); const record={paperId:paper.id,fileName:paper.fileName||`${paper.title}.pdf`,blob}; await saveOfflinePaper(record); await api.post(`/pack-delivery/paper/${paper.id}/downloaded`); setSaved(record) } catch(err){setError(errorMessage(err))} finally{setBusy(false)} }
  const open = () => { const url=URL.createObjectURL(saved.blob); window.open(url,'_blank','noopener,noreferrer'); window.setTimeout(()=>URL.revokeObjectURL(url),60000) }
  const remove = async () => { await removeOfflinePaper(paper.id); setSaved(null) }
  return <div className="offline-paper-control">{saved ? <><button className="secondary" onClick={open}><ExternalLink /> Open offline</button><button className="icon-button bordered" title="Remove offline copy" onClick={remove}><Trash2 /></button></> : <button className="secondary" disabled={busy} onClick={keep}><DownloadCloud />{busy?'Saving...':'Keep offline'}</button>}{error&&<small>{error}</small>}</div>
}
