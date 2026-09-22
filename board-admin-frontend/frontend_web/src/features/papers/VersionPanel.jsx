import { useCallback, useEffect, useState } from 'react'
import { ExternalLink, Upload } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { uploadFile } from '../../api/files'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'

const rowsFrom = data => Array.isArray(data) ? data : data?.content || data?.items || []

export default function VersionPanel({ paperId, canUpload }) {
  const [items, setItems] = useState([]); const [file, setFile] = useState(null); const [note, setNote] = useState(''); const [loading, setLoading] = useState(true); const [saving, setSaving] = useState(false); const [error, setError] = useState('')
  const load = useCallback(async () => { setLoading(true); setError(''); try { setItems(rowsFrom((await api.get(`/papers/${paperId}/versions`)).data)) } catch (err) { setError(errorMessage(err)) } finally { setLoading(false) } }, [paperId])
  useEffect(() => { load() }, [load])
  const submit = async event => { event.preventDefault(); if (!file) return; setSaving(true); try { const filePath = await uploadFile({ file, paperId }); await api.post(`/papers/${paperId}/versions`, { filePath, fileName: file.name, revisionNote: note.trim() || null }); setFile(null); setNote(''); event.currentTarget.reset(); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving(false) } }
  return <div className="page"><section className="panel"><div className="section-title"><div><h3>Version history</h3><p>Review revisions of this board paper.</p></div></div>{canUpload && <form className="attachment-upload" onSubmit={submit}><label className="secondary file-button"><Upload />Choose revision<input required type="file" accept="application/pdf" onChange={event => setFile(event.target.files?.[0] || null)} /></label><input value={note} onChange={event => setNote(event.target.value)} placeholder="Revision note" /><button className="primary" disabled={!file || saving}>{saving ? 'Uploading…' : 'Add revision'}</button></form>}{error && <ErrorState error={error} retry={load} />}{loading ? <LoadingState label="Loading versions…" /> : !items.length ? <EmptyState title="No previous versions" /> : <div className="attachment-grid">{items.map((item, index) => <article key={item.id || index}><div><h4>Version {item.versionNumber || index + 1}</h4><p>{item.revisionNote || item.fileName || 'Board paper revision'}</p></div>{item.filePath && <a className="secondary" href={item.filePath} target="_blank" rel="noreferrer"><ExternalLink />Open</a>}</article>)}</div>}</section></div>
}
