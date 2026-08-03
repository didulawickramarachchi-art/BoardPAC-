import { useEffect, useState } from 'react'
import { CalendarDays, FileText, Users, ClipboardCheck, ArrowUpRight, MapPin, Clock, AlertTriangle, Tags, Layers, ShieldCheck, MonitorSmartphone, BarChart3, Settings, Mail, MessageSquareText } from 'lucide-react'
import { Link } from 'react-router-dom'
import { api, errorMessage } from '../api/client'
import { useAuth } from '../state/AuthContext'

const rowsFrom = response => Array.isArray(response) ? response : response.content || response.items || []

export default function Dashboard() {
  const { user, role } = useAuth()
  const [data, setData] = useState(null)
  const [adminUsers, setAdminUsers] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    if (role === 'ADMIN') { setData({}); return }
    if (!user?.id) return
    const load = async () => {
      try {
        setError('')
        const { data: summary } = await api.get(`/dashboard/summary/${user.id}`)
        if (role !== 'SECRETARY') {
          setData(summary)
          return
        }
        const [{ data: meetingsResponse }, { data: categoriesResponse }, { data: subcategoriesResponse }] = await Promise.all([
          api.get('/meetings'),
          api.get('/categories'),
          api.get('/subcategories'),
        ])
        const meetings = rowsFrom(meetingsResponse)
        setData({
          ...summary,
          meetingCount: meetings.filter(item => String(item.type || '').toUpperCase() !== 'CIRCULAR').length,
          circularCount: meetings.filter(item => String(item.type || '').toUpperCase() === 'CIRCULAR').length,
          categoryCount: rowsFrom(categoriesResponse).length,
          subcategoryCount: rowsFrom(subcategoriesResponse).length,
        })
      } catch (e) {
        setError(errorMessage(e))
      }
    }
    load()
  }, [role, user?.id])

  useEffect(() => {
    if (role !== 'ADMIN') return
    api.get('/users').then(({ data: response }) => {
      setAdminUsers(Array.isArray(response) ? response : response.content || response.items || [])
    }).catch(e => setError(errorMessage(e)))
  }, [role])

  const normalizedRole = account => String(account.role || '').trim().toUpperCase().replace(/[\s-]+/g, '_')
  const adminRoles = ['ADMIN', 'SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM']
  const secretaryRoles = ['SECRETARY', 'BOARD_SECRETARY', 'ORGANIZER']
  const boardUsers = adminUsers || []
  const pendingUsers = boardUsers.filter(account => ['PENDING', 'REQUESTED', 'AWAITING_APPROVAL'].includes(String(account.status).toUpperCase()) || account.approved === false)
  const cards = role === 'ADMIN' ? [
    ['Members', boardUsers.filter(account => normalizedRole(account) === 'MEMBER').length, Users, '/users'],
    ['Secretaries', boardUsers.filter(account => secretaryRoles.includes(normalizedRole(account))).length, Users, '/users'],
    ['Admins', boardUsers.filter(account => adminRoles.includes(normalizedRole(account))).length, ShieldCheck, '/users'],
    ['Pending user approvals', pendingUsers.length, ClipboardCheck, '/users', 'danger-stat'],
  ] : role === 'SECRETARY' ? [
    ['Meetings', data?.meetingCount ?? data?.totalMeetings, CalendarDays, '/meetings', 'meeting-stat'],
    ['Circulars', data?.circularCount ?? data?.totalCirculars, Mail, '/meetings', 'circular-stat'],
    ['Unread Papers', data?.unreadPapers ?? data?.unreadPaperCount ?? 0, FileText, '/papers', 'paper-stat'],
    ['Shared Comments', data?.sharedComments ?? data?.sharedCommentCount ?? 0, MessageSquareText, '/papers', 'comment-stat'],
    ['Categories', data?.categoryCount ?? data?.totalCategories, Tags, '/categories', 'category-stat'],
    ['Subcategories', data?.subcategoryCount ?? data?.totalSubcategories, Layers, '/subcategories', 'subcategory-stat'],
  ].filter(c => c[1] != null) : [
    ['Meetings', data?.totalMeetings ?? data?.meetingCount, CalendarDays, '/meetings'],
    ['Board papers', data?.totalPapers ?? data?.paperCount, FileText, '/papers'],
    ['Pending approvals', data?.pendingApprovals, ClipboardCheck, '/approvals'],
    ['Active users', data?.activeUsers, Users, '/users'],
  ].filter(c => c[1] != null && (role === 'ADMIN' || c[0] !== 'Active users') && (role !== 'SECRETARY' || c[0] !== 'Pending approvals'))

  const quickActions = role === 'ADMIN'
    ? [[Users, 'Users', '/users'], [MonitorSmartphone, 'Devices', '/devices'], [BarChart3, 'Reports', '/reports'], [Settings, 'Settings', '/settings'], [ShieldCheck, 'Access Control', '/access-control']]
    : role === 'SECRETARY'
      ? [[CalendarDays, 'Browse meetings', '/meetings'], [FileText, 'Review papers', '/papers'], [Tags, 'Manage categories', '/categories'], [Layers, 'Manage subcategories', '/subcategories'], [ShieldCheck, 'Manage privileges', '/privileges']]
      : [[CalendarDays, 'Browse meetings', '/meetings'], [FileText, 'Review papers', '/papers'], [ClipboardCheck, 'Check approvals', '/approvals']]

  return <div className="page">
    <div className="welcome">
      <div><span className="eyebrow">{role} workspace</span><h2>Good {new Date().getHours() < 12 ? 'morning' : new Date().getHours() < 18 ? 'afternoon' : 'evening'}, {user?.displayName || user?.username}</h2><p>Here is what is happening across your board workspace today.</p></div>
      <div className="date-card"><b>{new Date().getDate()}</b><span>{new Date().toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}</span></div>
    </div>
    {error && <div className="alert error"><AlertTriangle />{error}</div>}
    <div className={`stats ${role === 'ADMIN' ? 'admin-stats' : role === 'SECRETARY' ? 'secretary-stats' : ''}`}>{(!data || (role === 'ADMIN' && !adminUsers)) && !error ? Array.from({ length: role === 'SECRETARY' ? 6 : 4 }, (_, index) => <div className="stat skeleton" key={index} />) : cards.map(([name, value, Icon, path, variant]) => <Link className={`stat ${variant || ''}`} to={path} key={name}><div className="stat-icon"><Icon /></div><span>{name}</span><strong>{value}</strong><ArrowUpRight className="stat-arrow" /></Link>)}</div>
    <div className={`dashboard-grid ${role === 'ADMIN' ? 'admin-dashboard-grid' : ''}`}>
      {role !== 'ADMIN' && <section className="meeting-feature">
        <span className="eyebrow">Next on the calendar</span>
        <h3>{data?.upcomingMeetingTitle || 'No upcoming meeting scheduled'}</h3>
        {data?.upcomingMeetingDateTime && <p><Clock />{data.upcomingMeetingDateTime}</p>}
        {data?.upcomingMeetingLocation && <p><MapPin />{data.upcomingMeetingLocation}</p>}
        <Link to="/meetings">View meeting schedule <ArrowUpRight /></Link>
      </section>}
      <section className="panel quick">
        <div className="section-title"><div><h3>Quick actions</h3><p>Frequently used tools</p></div></div>
        <div className="quick-grid">{quickActions.map(([Icon, label, path]) => <Link to={path} key={path}><Icon />{label}</Link>)}</div>
      </section>
    </div>
  </div>
}
