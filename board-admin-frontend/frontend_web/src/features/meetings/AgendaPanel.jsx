import { useCallback, useEffect, useMemo, useState } from 'react'
import { ChevronDown, ChevronUp, Plus, Share2, Trash2 } from 'lucide-react'
import { api, errorMessage } from '../../api/client'
import { collectionFrom } from '../../api/response'
import { EmptyState, ErrorState, LoadingState } from '../../components/AsyncState'
import { orderedIdsAfterMove } from './meetingPayloads'

const byOrder = (a, b) => (a.displayOrder ?? 0) - (b.displayOrder ?? 0)

export default function AgendaPanel({ meetingId, subcategoryId, userId, canManage }) {
  const [sections, setSections] = useState([])
  const [items, setItems] = useState([])
  const [paperCounts, setPaperCounts] = useState({})
  const [shared, setShared] = useState([])
  const [subcategories, setSubcategories] = useState([])
  const [sectionForm, setSectionForm] = useState({ title: '', numberLabel: '' })
  const [itemForm, setItemForm] = useState({ sectionId: '', itemType: 'HEADING', title: '', numberLabel: '', description: '' })
  const [shareForm, setShareForm] = useState({ agendaItemId: '', targetSubcategoryId: '' })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const load = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const requests = [api.get(`/agendas/sections/${meetingId}`), api.get(`/agendas/items/${meetingId}`)]
      if (canManage) requests.push(api.get('/subcategories'))
      if (subcategoryId) requests.push(api.get(`/agendas/shared/subcategory/${subcategoryId}`))
      const responses = await Promise.all(requests)
      setSections(collectionFrom(responses[0].data).sort(byOrder))
      const agendaItems = collectionFrom(responses[1].data).sort(byOrder)
      setItems(agendaItems)
      const paperResponses = await Promise.all(agendaItems.map(item => api.get(`/papers/agenda-item/${item.id}`)))
      setPaperCounts(Object.fromEntries(agendaItems.map((item, index) => [item.id, collectionFrom(paperResponses[index].data).length])))
      if (canManage) setSubcategories(collectionFrom(responses[2].data))
      if (subcategoryId) setShared(collectionFrom(responses[canManage ? 3 : 2].data))
    } catch (err) { setError(errorMessage(err)) }
    finally { setLoading(false) }
  }, [canManage, meetingId, subcategoryId])

  useEffect(() => { load() }, [load])
  const mutate = async (key, operation, message) => { setSaving(key); setError(''); try { await operation(); setNotice(message); await load() } catch (err) { setError(errorMessage(err)) } finally { setSaving('') } }
  const addSection = event => { event.preventDefault(); mutate('section', () => api.post('/agendas/sections', { meetingId, ...sectionForm, displayOrder: sections.length }), 'Agenda section added.').then(() => setSectionForm({ title: '', numberLabel: '' })) }
  const addItem = event => { event.preventDefault(); mutate('item', () => api.post('/agendas/items', { meetingId, ...itemForm, sectionId: Number(itemForm.sectionId), displayOrder: items.length }), 'Agenda item added.').then(() => setItemForm({ sectionId: '', itemType: 'HEADING', title: '', numberLabel: '', description: '' })) }
  const remove = (kind, id) => { if (!window.confirm(`Delete this agenda ${kind}?`)) return; mutate(`${kind}-${id}`, () => api.delete(`/agendas/${kind}s/${id}`), `Agenda ${kind} deleted.`) }
  const move = (kind, rows, id, direction) => mutate(`${kind}-${id}`, () => api.put(`/agendas/${kind}s/${meetingId}/order`, { orderedIds: orderedIdsAfterMove(rows, id, direction) }), 'Agenda order updated.')
  const share = event => { event.preventDefault(); mutate('share', () => api.post('/agendas/share', { agendaItemId: Number(shareForm.agendaItemId), targetSubcategoryId: Number(shareForm.targetSubcategoryId), sharedByUserId: userId }), 'Agenda item shared.').then(() => setShareForm({ agendaItemId: '', targetSubcategoryId: '' })) }
  const sectionName = useMemo(() => Object.fromEntries(sections.map(section => [section.id, section.title])), [sections])

  if (loading) return <div className="page"><LoadingState label="Loading agenda…" /></div>
  return <div className="page agenda-panel">{error && <ErrorState error={error} retry={load} />}{notice && <div className="alert success">{notice}</div>}
    <div className="agenda-grid"><section className="panel workflow-panel"><div className="section-title"><div><h3>Agenda sections</h3><p>Ordered groups for this meeting.</p></div></div>
      {canManage && <form className="compact-form" onSubmit={addSection}><input required placeholder="Section title" value={sectionForm.title} onChange={event => setSectionForm({ ...sectionForm, title: event.target.value })} /><input placeholder="Number" value={sectionForm.numberLabel} onChange={event => setSectionForm({ ...sectionForm, numberLabel: event.target.value })} /><button className="primary" disabled={saving === 'section'}><Plus />Add</button></form>}
      {!sections.length ? <EmptyState title="No agenda sections" /> : <div className="workflow-list">{sections.map((section, index) => <article key={section.id}><div><b>{section.numberLabel && `${section.numberLabel} `}{section.title}</b><small>{items.filter(item => item.sectionId === section.id).length} items</small></div>{canManage && <div className="order-actions"><button disabled={index === 0 || saving} onClick={() => move('section', sections, section.id, -1)} aria-label="Move section up"><ChevronUp /></button><button disabled={index === sections.length - 1 || saving} onClick={() => move('section', sections, section.id, 1)} aria-label="Move section down"><ChevronDown /></button><button disabled={saving} onClick={() => remove('section', section.id)} aria-label="Delete section"><Trash2 /></button></div>}</article>)}</div>}
    </section><section className="panel workflow-panel"><div className="section-title"><div><h3>Agenda items</h3><p>Meeting topics and supporting media.</p></div></div>
      {canManage && <form className="compact-form agenda-item-form" onSubmit={addItem}><select required value={itemForm.sectionId} onChange={event => setItemForm({ ...itemForm, sectionId: event.target.value })}><option value="">Select section</option>{sections.map(section => <option value={section.id} key={section.id}>{section.title}</option>)}</select><select value={itemForm.itemType} onChange={event => setItemForm({ ...itemForm, itemType: event.target.value })}>{['HEADING','SUB_HEADING','PAPER','AUDIO','VIDEO'].map(type => <option key={type} value={type}>{type.replaceAll('_',' ')}</option>)}</select><input required placeholder="Item title" value={itemForm.title} onChange={event => setItemForm({ ...itemForm, title: event.target.value })} /><input placeholder="Number" value={itemForm.numberLabel} onChange={event => setItemForm({ ...itemForm, numberLabel: event.target.value })} /><textarea placeholder="Description" value={itemForm.description} onChange={event => setItemForm({ ...itemForm, description: event.target.value })} /><button className="primary" disabled={saving === 'item' || !sections.length}><Plus />Add item</button></form>}
      {!items.length ? <EmptyState title="No agenda items" /> : <div className="workflow-list">{items.map((item, index) => <article key={item.id}><div><b>{item.numberLabel && `${item.numberLabel} `}{item.title}</b><small>{sectionName[item.sectionId] || item.itemType}{item.description ? ` · ${item.description}` : ''} · {paperCounts[item.id] || 0} papers</small></div>{canManage && <div className="order-actions"><button disabled={index === 0 || saving} onClick={() => move('item', items, item.id, -1)} aria-label="Move item up"><ChevronUp /></button><button disabled={index === items.length - 1 || saving} onClick={() => move('item', items, item.id, 1)} aria-label="Move item down"><ChevronDown /></button><button disabled={saving} onClick={() => remove('item', item.id)} aria-label="Delete item"><Trash2 /></button></div>}</article>)}</div>}
    </section></div>
    {canManage && <section className="panel workflow-panel share-panel"><div className="section-title"><div><h3>Share agenda item</h3><p>Make an agenda item available to another subcategory.</p></div></div><form className="compact-form" onSubmit={share}><select required value={shareForm.agendaItemId} onChange={event => setShareForm({ ...shareForm, agendaItemId: event.target.value })}><option value="">Select agenda item</option>{items.map(item => <option key={item.id} value={item.id}>{item.title}</option>)}</select><select required value={shareForm.targetSubcategoryId} onChange={event => setShareForm({ ...shareForm, targetSubcategoryId: event.target.value })}><option value="">Target subcategory</option>{subcategories.filter(item => Number(item.id) !== Number(subcategoryId)).map(item => <option key={item.id} value={item.id}>{item.displayName || item.name}</option>)}</select><button className="primary" disabled={saving === 'share'}><Share2 />Share</button></form></section>}
    {subcategoryId && <section className="panel workflow-panel share-panel"><div className="section-title"><div><h3>Shared agenda</h3><p>Items shared with this meeting’s subcategory.</p></div></div>{!shared.length ? <EmptyState title="No shared agenda items" /> : <div className="workflow-list">{shared.map(item => <article key={item.id}><div><b>{item.sourceAgendaItemTitle}</b><small>From {item.sourceSubcategoryName} · Shared by {item.sharedByUsername}</small></div></article>)}</div>}</section>}
  </div>
}
