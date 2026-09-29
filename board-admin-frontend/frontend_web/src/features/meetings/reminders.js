const KEY = 'boardpac_meeting_reminder_offsets'
const timers = new Map()
export const reminderOptions = {10080:'1 week before',2880:'2 days before',1440:'1 day before',120:'2 hours before',60:'1 hour before',30:'30 minutes before'}
export const getReminderOffsets = () => { try { const value=JSON.parse(localStorage.getItem(KEY)); return Array.isArray(value)?value:[1440,60] } catch { return [1440,60] } }
export const setReminderOffsets = values => localStorage.setItem(KEY,JSON.stringify([...new Set(values)].sort((a,b)=>b-a)))
export const clearReminderTimers = () => { timers.forEach(window.clearTimeout); timers.clear() }
export const scheduleMeetingReminders = meetings => {
  clearReminderTimers(); if (!('Notification' in window)||Notification.permission!=='granted') return 0
  const now=Date.now(), max=2147483647; let count=0
  for(const meeting of meetings) for(const minutes of getReminderOffsets()) { const at=new Date(meeting.meetingDateTime).getTime()-minutes*60000, delay=at-now; if(delay>0&&delay<=max){const key=`${meeting.id}-${minutes}`;timers.set(key,window.setTimeout(()=>new Notification(minutes>=1440?`Meeting in ${minutes/1440} day(s)`:`Meeting in ${minutes>=60?minutes/60+' hour(s)':minutes+' minutes'}`,{body:`${meeting.title} starts at ${new Date(meeting.meetingDateTime).toLocaleString()}`,tag:`meeting-${key}`}),delay));count++} }
  return count
}
