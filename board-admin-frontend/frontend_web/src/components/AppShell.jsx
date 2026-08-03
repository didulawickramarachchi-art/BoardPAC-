import { useEffect, useMemo, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { BarChart3, Bell, CalendarDays, ChevronLeft, ClipboardCheck, FileText, Heart, Layers, LayoutDashboard, LogOut, MailCheck, Megaphone, Menu, MonitorSmartphone, Search, Send, Settings, ShieldCheck, Tags, ThumbsUp, Truck, Users, X } from 'lucide-react'
import { api, errorMessage } from '../api/client'
import { useAuth } from '../state/AuthContext'

const groups = [
  ['Overview', [['Dashboard', '/dashboard', LayoutDashboard, ['ADMIN', 'SECRETARY', 'MEMBER']]]],
  ['Board operations', [['Meetings', '/meetings', CalendarDays, ['SECRETARY', 'MEMBER']], ['Board papers', '/papers', FileText, ['SECRETARY', 'MEMBER']], ['Approvals', '/approvals', ClipboardCheck, ['MEMBER']], ['Pack delivery', '/pack-delivery', Truck, ['MEMBER']]]],
  ['Organization', [['Users', '/users', Users, ['ADMIN']], ['Categories', '/categories', Tags, ['SECRETARY', 'MEMBER']], ['Subcategories', '/subcategories', Layers, ['SECRETARY', 'MEMBER']], ['Privileges', '/privileges', ShieldCheck, ['SECRETARY']], ['Devices', '/devices', MonitorSmartphone, ['ADMIN']], ['Access Control', '/access-control', ShieldCheck, ['ADMIN']]]],
  ['Insights', [['Reports', '/reports', BarChart3, ['ADMIN']], ['Settings', '/settings', Settings, ['ADMIN']]]],
]

const rowsFrom = data => Array.isArray(data) ? data : data?.notifications || data?.items || data?.content || []
const initials = name => String(name || 'System').split(/\s+/).map(part => part[0]).join('').slice(0, 2).toUpperCase()
const formatDate = value => {
  const date = value ? new Date(value) : null
  return date && !Number.isNaN(date.getTime()) ? date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''
}
const notificationTone = type => ({
  ANNOUNCEMENT: 'announcement',
  COMMENT_SHARED: 'comment',
  DOCUMENT_UPLOADED: 'document',
  PAPER_CREATED: 'paper',
  PAPER_SHARED: 'paper',
  MEETING_CREATED: 'meeting',
})[String(type || '').toUpperCase()] || 'general'

function NotificationPanel({ user, role, onClose, onUnreadChange }) {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [announcementOpen, setAnnouncementOpen] = useState(false)
  const [announcement, setAnnouncement] = useState({ title: '', message: '' })
  const [saving, setSaving] = useState('')
  const userId = user?.id
  const canAnnounce = role === 'SECRETARY'

  const load = async () => {
    if (!userId) return
    setLoading(true); setError('')
    try {
      const { data } = await api.get(`/notifications/user/${userId}`)
      const nextItems = rowsFrom(data)
      setItems(nextItems)
      onUnreadChange(nextItems.filter(item => !item.read).length)
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [userId])

  const clear = async () => {
    if (!userId || items.length === 0) return
    setSaving('clear'); setError('')
    try {
      await api.delete(`/notifications/user/${userId}`)
      setItems([])
      onUnreadChange(0)
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving('')
    }
  }

  const markRead = async () => {
    if (!userId) return
    setSaving('read'); setError('')
    try {
      await api.put(`/notifications/user/${userId}/read`)
      setItems(current => current.map(item => ({ ...item, read: true })))
      onUnreadChange(0)
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving('')
    }
  }

  const sendAnnouncement = async event => {
    event.preventDefault()
    if (!userId || !announcement.title.trim() || !announcement.message.trim()) return
    setSaving('announcement'); setError('')
    try {
      await api.post('/notifications/announcement', {
        title: announcement.title.trim(),
        message: announcement.message.trim(),
        type: 'ANNOUNCEMENT',
        createdByUserId: userId,
        announcement: true,
      })
      setAnnouncement({ title: '', message: '' })
      setAnnouncementOpen(false)
      await load()
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving('')
    }
  }

  const updateNotification = updated => setItems(current => {
    const nextItems = current.map(item => (item.id === updated.id ? updated : item))
    onUnreadChange(nextItems.filter(item => !item.read).length)
    return nextItems
  })

  const react = async (notificationId, reactionType) => {
    setSaving(`react-${notificationId}-${reactionType}`); setError('')
    try {
      const { data } = await api.post(`/notifications/${notificationId}/reaction`, { reactionType })
      updateNotification(data)
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving('')
    }
  }

  return <div className="notification-layer" role="dialog" aria-modal="true" aria-label="Notifications">
    <button className="notification-backdrop" aria-label="Close notifications" onClick={onClose} />
    <section className="notification-panel">
      <div className="notification-grip" />
      <div className="notification-header">
        <div className="notification-title-icon"><Bell /></div>
        <div><h2>Notifications</h2><p>{items.filter(item => !item.read).length} unread</p></div>
        <div className="notification-header-actions">
          <button className="text-button" disabled={saving === 'read' || items.length === 0} onClick={markRead}>Mark read</button>
          <button className="text-button" disabled={saving === 'clear' || items.length === 0} onClick={clear}>Clear</button>
          <button className="icon-button" aria-label="Close notifications" onClick={onClose}><X /></button>
        </div>
      </div>

      {canAnnounce && <div className="announcement-box">
        <button className="primary wide" onClick={() => setAnnouncementOpen(value => !value)}><Megaphone /> Create Announcement</button>
        {announcementOpen && <form className="announcement-form" onSubmit={sendAnnouncement}>
          <input placeholder="Title" value={announcement.title} onChange={event => setAnnouncement({ ...announcement, title: event.target.value })} />
          <textarea placeholder="Message" value={announcement.message} onChange={event => setAnnouncement({ ...announcement, message: event.target.value })} />
          <button className="primary" disabled={saving === 'announcement'}><Send /> {saving === 'announcement' ? 'Sending...' : 'Send'}</button>
        </form>}
      </div>}

      {error && <div className="alert error">{error}</div>}
      <div className="notification-list">
        {loading ? <div className="state compact"><div className="spinner" /><h3>Loading notifications...</h3></div> : items.length === 0 ? <div className="notification-empty"><MailCheck /><h3>No notifications yet</h3></div> : items.map(item => <NotificationItem key={item.id} item={item} saving={saving} onReact={type => react(item.id, type)} />)}
      </div>
    </section>
  </div>
}

function NotificationItem({ item, saving, onReact }) {
  const tone = notificationTone(item.type || item.notificationType)
  const reactions = [['LIKE', ThumbsUp], ['LOVE', Heart], ['OK', ClipboardCheck]]
  const replies = Array.isArray(item.replies) ? item.replies : []

  return <article className={`notification-item ${item.read ? 'read' : 'unread'} ${tone}`}>
    <div className="notification-avatar">
      {item.createdByProfilePictureUrl ? <img src={item.createdByProfilePictureUrl} alt="" /> : <span>{initials(item.createdByName)}</span>}
    </div>
    <div className="notification-body">
      <div className="notification-meta"><b>{item.createdByName || 'System'}</b><span>{formatDate(item.createdAt || item.createdDate)}</span></div>
      <h3>{item.title || item.subject || 'Notification'}</h3>
      {(item.message || item.body) && <p>{item.message || item.body}</p>}
      <div className="notification-reactions">{reactions.map(([type, Icon]) => {
        const selected = item.currentReaction === type
        return <button type="button" className={selected ? 'selected' : ''} disabled={saving === `react-${item.id}-${type}`} onClick={() => onReact(type)} key={type}><Icon />{item.reactionCounts?.[type] || 0}</button>
      })}</div>
      {replies.length > 0 && <div className="notification-replies">{replies.slice(-2).map(reply => <p key={reply.id}><b>{reply.userName || 'User'}:</b> {reply.message}</p>)}</div>}
    </div>
  </article>
}

export default function AppShell() {
  const [open, setOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(false)
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [unreadCount, setUnreadCount] = useState(0)
  const { user, role, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const title = useMemo(() => [...groups.flatMap(g => g[1])].find(i => location.pathname.startsWith(i[1]))?.[0] || 'Board Management', [location.pathname])

  useEffect(() => {
    if (!user?.id) return
    let active = true
    api.get(`/notifications/user/${user.id}`)
      .then(({ data }) => { if (active) setUnreadCount(rowsFrom(data).filter(item => !item.read).length) })
      .catch(() => { if (active) setUnreadCount(0) })
    return () => { active = false }
  }, [user?.id, notificationsOpen])

  const openNotifications = async () => {
    if (user?.id && unreadCount > 0) {
      setUnreadCount(0)
      try { await api.put(`/notifications/user/${user.id}/read`) } catch { /* Badge still clears like mobile tap behavior. */ }
    }
    setNotificationsOpen(true)
  }

  return <div className={`shell ${collapsed ? 'collapsed' : ''}`}>
    {open && <button className="backdrop" aria-label="Close menu" onClick={() => setOpen(false)} />}
    <aside className={`sidebar ${open ? 'open' : ''}`}>
      <div className="brand"><img src="/assets/slpa_logo.png" alt="SLPA" /><div><b>SLPA Board</b><span>Management System</span></div><button className="mobile-close" onClick={() => setOpen(false)}><X /></button></div>
      <nav>{groups.map(([group, items]) => {
        const allowed = items.filter(i => i[3].includes(role))
        return allowed.length ? <div className="nav-group" key={group}><small>{group}</small>{allowed.map(([label, path, Icon]) => <NavLink key={path} to={path} onClick={() => setOpen(false)} title={label}><Icon /><span>{label}</span></NavLink>)}</div> : null
      })}</nav>
      <button className="collapse" type="button" aria-label={collapsed ? 'Expand menu' : 'Collapse menu'} aria-expanded={!collapsed} onClick={() => setCollapsed(value => !value)}><ChevronLeft /><span>{collapsed ? 'Expand menu' : 'Collapse menu'}</span></button>
    </aside>
    <div className="workspace">
      <header className="topbar">
        <button className="menu-button" aria-label="Open menu" onClick={() => setOpen(true)}><Menu /></button>
        <div><p>SLPA Board</p><h1>{title}</h1></div>
        <label className="global-search"><Search /><input placeholder="Search anything..." /></label>
        <button className="icon-button notification-trigger" aria-label="Notifications" onClick={openNotifications}><Bell />{unreadCount > 0 && <span>{unreadCount > 99 ? '99+' : unreadCount}</span>}</button>
        <NavLink to="/profile" className="user" title="Open profile"><div className="avatar">{initials(user?.displayName || user?.username || 'U')}</div><div><b>{user?.displayName || user?.username}</b><span>{role}</span></div></NavLink>
        <button className="icon-button" title="Sign out" onClick={() => { logout(); navigate('/login') }}><LogOut /></button>
      </header>
      <main><Outlet /></main>
    </div>
    {notificationsOpen && <NotificationPanel user={user} role={role} onClose={() => setNotificationsOpen(false)} onUnreadChange={setUnreadCount} />}
  </div>
}
