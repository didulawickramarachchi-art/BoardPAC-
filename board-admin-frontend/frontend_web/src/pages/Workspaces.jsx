import { useEffect, useState } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { CalendarDays, ChevronLeft, Clock3, FileText, ListTree, MapPin, MessageSquare, Users } from 'lucide-react'
import ResourcePage from './ResourcePage'
import { useAuth } from '../state/AuthContext'
import { api } from '../api/client'
import { collectionFrom } from '../api/response'
import { ActionItems, MeetingMinutes, PrivateNotes } from '../features/meetings/WorkspacePanels'
import { meetingListEndpoint, permissionsFor } from '../auth/permissions'
import AttachmentPanel from '../features/papers/AttachmentPanel'
import AnnotationWorkspace from '../features/annotations/AnnotationWorkspace'
import CommentsPanel from '../features/comments/CommentsPanel'
import VersionPanel from '../features/papers/VersionPanel'
import AgendaPanel from '../features/meetings/AgendaPanel'
import ParticipantsPanel from '../features/meetings/ParticipantsPanel'
import FavoriteButton from '../features/favorites/FavoriteButton'
import PaperHeader from '../features/papers/PaperHeader'
import { preparePaperPayload } from '../features/papers/paperPayloads'

const TabHeader=({title,description,tabs,tab,setTab})=><div className="page workspace-heading"><h2>{title}</h2><p>{description}</p><div className="tabs">{tabs.map(name=><button type="button" className={tab===name?'active':''} onClick={()=>setTab(name)} key={name}>{name}</button>)}</div></div>

export function MeetingWorkspace(){const {id}=useParams();const meetingId=Number(id);const {user}=useAuth();const [tab,setTab]=useState('agenda');const [meeting,setMeeting]=useState(null);const access=permissionsFor(user);const manager=access.canManageMeetings;const meetingsEndpoint=meetingListEndpoint(user);useEffect(()=>{api.get(meetingsEndpoint).then(({data})=>setMeeting(collectionFrom(data).find(item=>Number(item.id)===meetingId)||null))},[meetingId,meetingsEndpoint]);return <div><section className="meeting-detail-hero"><Link to="/meetings" className="meeting-back"><ChevronLeft/> Meetings</Link><div className="meeting-detail-main"><div className="meeting-date-icon"><CalendarDays/></div><div><div className="meeting-kicker"><span>{meeting?.type||'MEETING'}</span><span className={`badge ${String(meeting?.status||'').toLowerCase()}`}>{meeting?.status||'Loading'}</span></div><h2>{meeting?.title||`Meeting #${id}`}</h2><p>{meeting?.description||'Open the agenda or meeting papers below.'}</p><div className="meeting-meta">{meeting?.meetingDateTime&&<span><Clock3/>{new Date(meeting.meetingDateTime).toLocaleString()}</span>}{meeting?.location&&<span><MapPin/>{meeting.location}</span>}</div></div></div><div className="meeting-primary-actions"><button className={tab==='agenda'?'active':''} onClick={()=>setTab('agenda')}><ListTree/><span><b>Agenda</b><small>Sections and agenda items</small></span></button><button className={tab==='papers'?'active':''} onClick={()=>setTab('papers')}><FileText/><span><b>Papers</b><small>Documents for this meeting</small></span></button></div><div className="meeting-secondary-actions"><button className={tab==='participants'?'active':''} onClick={()=>setTab('participants')}><Users/> Participants</button><button className={tab==='comments'?'active':''} onClick={()=>setTab('comments')}><MessageSquare/> Comments</button><button className={tab==='notes'?'active':''} onClick={()=>setTab('notes')}>Notes</button><button className={tab==='minutes'?'active':''} onClick={()=>setTab('minutes')}>Minutes</button><button className={tab==='actions'?'active':''} onClick={()=>setTab('actions')}>Actions</button></div></section>
<div className="meeting-workspace-tools"><FavoriteButton type="MEETING" id={meetingId}/></div>
{tab==='agenda'&&<AgendaPanel meetingId={meetingId} subcategoryId={meeting?.subcategoryId} userId={user.id} canManage={manager}/>}
{tab==='papers'&&<ResourcePage title="Board Papers" description="Papers attached to this meeting." endpoint={`/papers/meeting/${id}`} createEndpoint={manager?'/papers':undefined} preparePayload={preparePaperPayload} initialValues={{meetingId,requiresApproval:false,isMainPaper:false}} actions={[{label:'Open',link:r=>`/papers/${r.id}?tab=annotations`}]} fields={[{name:'meetingId',type:'hidden'},{name:'agendaItemId',label:'Agenda item',optionsEndpoint:`/agendas/items/${id}`,optionLabel:'title'},{name:'paperType',label:'Paper type',type:'select',options:['APPROVAL','INFORMATION','DISCUSSION_ITEM','DISCUSSION_PAPER','SUPPORTING_DOCUMENT'],required:true},{name:'title',label:'Title',required:true},{name:'sourceFile',label:'Primary paper file',type:'file',accept:'application/pdf',required:true,full:true},{name:'referenceNumber',label:'Reference number'},{name:'versionNumber',label:'Version',type:'number'},{name:'requiresApproval',label:'Requires approval',type:'checkbox'},{name:'isMainPaper',label:'Main paper',type:'checkbox'},{name:'disclaimerMessage',label:'Disclaimer',type:'textarea',full:true}]}/>} 
{tab==='participants'&&<ParticipantsPanel meetingId={meetingId} user={user} canManage={manager} meetingClosed={String(meeting?.status).toUpperCase()==='CLOSED'}/>}
{tab==='comments'&&<CommentsPanel kind="meeting" targetId={meetingId} user={user} canComment={access.canCommentPapers}/>}
{tab==='notes'&&<PrivateNotes meetingId={meetingId}/>} 
{tab==='minutes'&&<MeetingMinutes meetingId={meetingId} canManage={manager}/>}
{tab==='actions'&&<ActionItems meetingId={meetingId} user={user} canManage={manager}/>}</div>}

export function PaperWorkspace(){const {id}=useParams();const paperId=Number(id);const {user}=useAuth();const access=permissionsFor(user);const [params,setParams]=useSearchParams();const tabs=['attachments','versions','approvals','comments','annotations',...(access.role==='SECRETARY'?['delivery']:[])];const requested=params.get('tab');const defaultTab=access.canAnnotatePapers?'annotations':'attachments';const tab=tabs.includes(requested)?requested:defaultTab;const setTab=next=>setParams(next===defaultTab?{}:{tab:next});return <div><PaperHeader paperId={paperId} user={user} canShare={access.role==='SECRETARY'} onOpen={()=>setTab(defaultTab)}/><TabHeader title="Paper workspace" description="Review documents, decisions, comments, annotations and delivery." tabs={tabs} tab={tab} setTab={setTab}/>
{tab==='attachments'&&<AttachmentPanel paperId={paperId} canUpload={access.canUploadPapers}/>} 
{tab==='versions'&&<VersionPanel paperId={paperId} canUpload={access.canUploadPapers}/>} 
{tab==='approvals'&&<ResourcePage title="Approvals" description="Submit a decision for this paper." endpoint={`/approvals/paper/${id}`} createEndpoint={access.canApprovePapers?'/approvals':undefined} initialValues={{paperId}} fields={[{name:'paperId',type:'hidden'},{name:'approvalStatus',label:'Decision',type:'select',options:['APPROVE','REJECT','ABSTAIN','INTEREST','RPT'],required:true},{name:'approvalComment',label:'Comment',type:'textarea',full:true}]}/>} 
{tab==='comments'&&<CommentsPanel kind="paper" targetId={paperId} user={user} canComment={access.canCommentPapers}/>} 
{tab==='annotations'&&access.canAnnotatePapers&&<AnnotationWorkspace paperId={paperId} userId={user.id}/>} 
{tab==='annotations'&&!access.canAnnotatePapers&&<div className="page"><div className="alert error">Your access profile does not allow private annotations.</div></div>} 
{tab==='delivery'&&<ResourcePage title="Pack Delivery" description="Delivery status for this paper." endpoint={`/pack-delivery/paper/${id}`}/>}</div>}
