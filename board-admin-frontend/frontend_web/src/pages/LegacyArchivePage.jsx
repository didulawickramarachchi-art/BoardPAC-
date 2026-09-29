import { useEffect, useState } from 'react'
import { api, errorMessage } from '../api/client'

export default function LegacyArchivePage() {
  const [page, setPage] = useState(0)
  const [papers, setPapers] = useState([])
  const [selected, setSelected] = useState(null)
  const [comments, setComments] = useState([])
  const [approvals, setApprovals] = useState([])
  const [decisions, setDecisions] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    setLoading(true)
    setError('')
    api.get('/legacy-archive/papers', { params: { page } })
      .then(({ data }) => { if (active) setPapers(data) })
      .catch(err => { if (active) setError(errorMessage(err)) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [page])

  const open = async id => {
    setError('')
    try {
      const [paper, paperComments, paperApprovals, paperDecisions] = await Promise.all([
        api.get(`/legacy-archive/papers/${id}`),
        api.get(`/legacy-archive/papers/${id}/comments`),
        api.get(`/legacy-archive/papers/${id}/approval-comments`),
        api.get(`/legacy-archive/papers/${id}/decisions`),
      ])
      setSelected(paper.data)
      setComments(paperComments.data)
      setApprovals(paperApprovals.data)
      setDecisions(paperDecisions.data)
    } catch (err) { setError(errorMessage(err)) }
  }

  const download = async paper => {
    setError('')
    try {
      const { data, headers } = await api.get(`/legacy-archive/papers/${paper.paper_id}/file`, { responseType: 'blob', timeout: 120000 })
      const extension = String(headers['content-type']).includes('presentationml') ? 'pptx' : 'pdf'
      const url = URL.createObjectURL(data)
      const link = document.createElement('a')
      link.href = url
      link.download = `legacy-paper-${paper.paper_id}.${extension}`
      link.click()
      setTimeout(() => URL.revokeObjectURL(url), 60000)
    } catch (err) { setError(errorMessage(err)) }
  }

  return <div className="page">
    <div className="page-heading"><div><span className="breadcrumb">Home / Legacy archive</span><h2>Legacy paper archive</h2><p>Browse all imported old papers, including those without a confirmed meeting. This view is read only.</p></div></div>
    {error && <div className="alert error" role="alert">{error}</div>}
    <section className="panel">
      {loading ? <p>Loading papers...</p> : <div className="table-wrap"><table><thead><tr><th>Old paper ID</th><th>Title</th><th>Meeting</th><th>Reference</th><th>File</th><th /></tr></thead><tbody>
        {papers.map(paper => <tr key={paper.paper_id}><td>{paper.paper_id}</td><td>{paper.title}</td><td>{paper.meeting_title || 'Unplaced'}</td><td>{paper.reference_number || '—'}</td><td>{paper.has_file ? 'Available' : 'Document unavailable'}</td><td><button type="button" className="secondary" onClick={() => open(paper.paper_id)}>View</button></td></tr>)}
      </tbody></table></div>}
      <div className="modal-actions"><button type="button" className="secondary" disabled={page === 0} onClick={() => setPage(value => value - 1)}>Previous</button><span>Page {page + 1}</span><button type="button" className="secondary" disabled={papers.length < 100} onClick={() => setPage(value => value + 1)}>Next</button></div>
    </section>
    {selected && <section className="panel"><h3>{selected.title}</h3><p>Old paper ID: {selected.paper_id} · Meeting: {selected.meeting_title || 'Unplaced'} · Source heading: {selected.source_heading_id ?? 'Unknown'} · Reference: {selected.reference_number || '—'}</p>
      {selected.has_file && <button type="button" className="primary" onClick={() => download(selected)}>Download document</button>}
      {!selected.has_file && <p role="status">Document unavailable. The paper record is preserved, but no readable file was recovered.</p>}
      <h4>Archived comments ({comments.length})</h4>{comments.map(comment => <p key={comment.comment_id}><b>User {comment.created_by}:</b> {comment.comment_text}</p>)}
      <h4>Approval comments ({approvals.length})</h4>{approvals.map(comment => <p key={comment.user_id}><b>User {comment.user_id}:</b> {comment.comment_text}</p>)}
      <h4>Historical decision codes ({decisions.length})</h4><p>Codes are retained from the old system and have not been mapped to the new approval workflow.</p>
      {decisions.length > 0 && <div className="table-wrap"><table><thead><tr><th>User ID</th><th>Decision code</th><th>Approval date</th><th>Viewed date</th></tr></thead><tbody>{decisions.map(decision => <tr key={decision.user_id}><td>{decision.user_id}</td><td>{decision.decision_status ?? '—'}</td><td>{decision.approval_date || '—'}</td><td>{decision.viewed_date || '—'}</td></tr>)}</tbody></table></div>}
    </section>}
  </div>
}
