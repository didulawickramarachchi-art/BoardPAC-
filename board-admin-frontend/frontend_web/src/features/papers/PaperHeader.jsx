import { useCallback, useEffect, useState } from 'react'
import { Download, Highlighter, Send } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import FavoriteButton from '../favorites/FavoriteButton'
import OfflinePaperButton from './OfflinePaperButton'
import { downloadProtectedPaper, fetchProtectedPaper } from './paperPayloads'

export default function PaperHeader({ paperId, user, canShare, onPaper, onOpen }) {
  const [paper, setPaper] = useState(null); const [readState, setReadState] = useState(null); const [users, setUsers] = useState([]); const [recipient, setRecipient] = useState(''); const [busy, setBusy] = useState(''); const [notice, setNotice] = useState(''); const [error, setError] = useState('')
  const load = useCallback(async () => {
    setError('')
    try {
      const { data } = await api.get(`/papers/${paperId}`)
      setPaper(data)
      onPaper?.(data)

      const [readResult, usersResult] = await Promise.allSettled([
        api.get(`/paper-read-states/${paperId}`),
        canShare ? api.get('/users') : Promise.resolve(null),
      ])
      if (readResult.status === 'fulfilled') setReadState(readResult.value.data)
      if (canShare && usersResult.status === 'fulfilled' && usersResult.value) setUsers(collectionFrom(usersResult.value.data))
      api.put(`/papers/${paperId}/read`).catch(() => {})
    } catch (err) {
      setError(errorMessage(err))
    }
  }, [canShare, onPaper, paperId])
  useEffect(() => { load() }, [load])
  const open = async () => {
    if (!paper) return
    if (onOpen) {
      onOpen()
      return
    }
    const viewer = window.open('', '_blank')
    if (!viewer) {
      setError('Allow pop-ups for this site, then try opening the paper again.')
      return
    }
    setBusy('open'); setError('')
    try {
      const blob = await fetchProtectedPaper({ paperId: paper.id, userId: user.id })
      const objectUrl = URL.createObjectURL(blob)
      viewer.opener = null
      viewer.location.href = objectUrl
      window.setTimeout(() => URL.revokeObjectURL(objectUrl), 300000)
    } catch (err) {
      viewer.close()
      setError(errorMessage(err))
    } finally {
      setBusy('')
    }
  }
  const download = async () => { if (!paper) return; setBusy('download'); setError(''); try { await downloadProtectedPaper({ paper, userId: user.id }); setNotice('Paper downloaded and delivery acknowledged.') } catch (err) { setError(errorMessage(err)) } finally { setBusy('') } }
  const share = async event => { event.preventDefault(); if (!recipient) return; setBusy('share'); setError(''); try { await api.post('/papers/share', { paperId, sharedByUserId: user.id, sharedToUserId: Number(recipient) }); setRecipient(''); setNotice('Paper shared successfully.') } catch (err) { setError(errorMessage(err)) } finally { setBusy('') } }
  return <section className="paper-detail-header"><div><span className="eyebrow">{paper?.paperType || 'BOARD PAPER'}</span><h2>{paper?.title || `Paper #${paperId}`}</h2><p>{paper?.referenceNumber || paper?.fileName || 'Loading paper details...'}</p><div className="paper-meta"><span>Version {paper?.versionNumber || 1}</span>{readState?.lastPage > 0 && <span>Resume at page {readState.lastPage}{readState.totalPages ? ` of ${readState.totalPages}` : ''}</span>}{paper?.requiresApproval && <span>Approval required</span>}</div></div><div className="paper-header-actions"><FavoriteButton type="PAPER" id={paperId}/>{paper&&<OfflinePaperButton paper={paper} userId={user.id}/>}<button className="secondary" disabled={!paper || Boolean(busy)} onClick={open}><Highlighter />{busy === 'open' ? 'Opening...' : 'Open & annotate'}</button><button className="primary" disabled={!paper || Boolean(busy)} onClick={download}><Download />{busy === 'download' ? 'Downloading...' : 'Download'}</button></div>{canShare && <form className="paper-share" onSubmit={share}><select required value={recipient} onChange={event => setRecipient(event.target.value)}><option value="">Share with user</option>{users.filter(account => Number(account.id) !== Number(user.id)).map(account => <option key={account.id} value={account.id}>{account.displayName || account.username}</option>)}</select><button className="secondary" disabled={busy === 'share'}><Send />Share</button></form>}{notice && <div className="alert success">{notice}</div>}{error && <div className="alert error">{error}</div>}</section>
}
