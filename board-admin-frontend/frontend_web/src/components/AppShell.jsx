import { useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { LayoutDashboard, CalendarDays, FileText, Users, Tags, Layers, ShieldCheck, MonitorSmartphone, ClipboardCheck, Truck, BarChart3, Settings, Menu, Search, Bell, LogOut, X, ChevronLeft } from 'lucide-react'
import { useAuth } from '../state/AuthContext'

const groups = [
  ['Overview', [['Dashboard', '/dashboard', LayoutDashboard, ['ADMIN','SECRETARY','MEMBER']]]],
  ['Board operations', [['Meetings', '/meetings', CalendarDays, ['SECRETARY','MEMBER']], ['Board papers', '/papers', FileText, ['SECRETARY','MEMBER']], ['Approvals', '/approvals', ClipboardCheck, ['MEMBER']], ['Pack delivery', '/pack-delivery', Truck, ['MEMBER']]]],
  ['Organization', [['Users', '/users', Users, ['ADMIN']], ['Categories', '/categories', Tags, ['SECRETARY','MEMBER']], ['Subcategories', '/subcategories', Layers, ['SECRETARY','MEMBER']], ['Privileges', '/privileges', ShieldCheck, ['SECRETARY']], ['Devices', '/devices', MonitorSmartphone, ['ADMIN']], ['Access Control', '/access-control', ShieldCheck, ['ADMIN']]]],
  ['Insights', [['Reports', '/reports', BarChart3, ['ADMIN']], ['Settings', '/settings', Settings, ['ADMIN']]]],
]

export default function AppShell() {
  const [open, setOpen] = useState(false); const [collapsed, setCollapsed] = useState(false)
  const { user, role, logout } = useAuth(); const navigate = useNavigate(); const location = useLocation()
  const title = [...groups.flatMap(g => g[1])].find(i => location.pathname.startsWith(i[1]))?.[0] || 'Board Management'
  return <div className={`shell ${collapsed ? 'collapsed' : ''}`}>
    {open && <button className="backdrop" aria-label="Close menu" onClick={() => setOpen(false)} />}
    <aside className={`sidebar ${open ? 'open' : ''}`}>
      <div className="brand"><img src="/assets/slpa_logo.png" alt="SLPA"/><div><b>SLPA Board</b><span>Management System</span></div><button className="mobile-close" onClick={() => setOpen(false)}><X/></button></div>
      <nav>{groups.map(([group, items]) => { const allowed = items.filter(i => i[3].includes(role)); return allowed.length ? <div className="nav-group" key={group}><small>{group}</small>{allowed.map(([label,path,Icon]) => <NavLink key={path} to={path} onClick={() => setOpen(false)} title={label}><Icon/><span>{label}</span></NavLink>)}</div> : null })}</nav>
      <button className="collapse" type="button" aria-label={collapsed ? 'Expand menu' : 'Collapse menu'} aria-expanded={!collapsed} onClick={() => setCollapsed(value => !value)}><ChevronLeft/><span>{collapsed ? 'Expand menu' : 'Collapse menu'}</span></button>
    </aside>
    <div className="workspace"><header className="topbar"><button className="menu-button" aria-label="Open menu" onClick={() => setOpen(true)}><Menu/></button><div><p>SLPA Board</p><h1>{title}</h1></div><label className="global-search"><Search/><input placeholder="Search anything…" /></label><button className="icon-button" aria-label="Notifications"><Bell/></button><NavLink to="/profile" className="user" title="Open profile"><div className="avatar">{(user?.displayName || user?.username || 'U').split(/\s+/).map(part=>part[0]).join('').slice(0,2).toUpperCase()}</div><div><b>{user?.displayName || user?.username}</b><span>{role}</span></div></NavLink><button className="icon-button" title="Sign out" onClick={() => { logout(); navigate('/login') }}><LogOut/></button></header><main><Outlet/></main></div>
  </div>
}
