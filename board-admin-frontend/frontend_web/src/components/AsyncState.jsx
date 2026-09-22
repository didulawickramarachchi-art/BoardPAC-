import { AlertTriangle, Inbox } from 'lucide-react'

export function LoadingState({ label = 'Loading…', compact = false }) {
  return <div className={`state ${compact ? 'compact' : ''}`} role="status"><div className="spinner" /><h3>{label}</h3></div>
}
export function ErrorState({ error, retry }) {
  return <div className="state" role="alert"><AlertTriangle /><h3>Something went wrong</h3><p>{error}</p>{retry && <button className="secondary" onClick={retry}>Try again</button>}</div>
}
export function EmptyState({ title = 'Nothing here yet', detail = 'New records will appear here.' }) {
  return <div className="state"><Inbox /><h3>{title}</h3><p>{detail}</p></div>
}
