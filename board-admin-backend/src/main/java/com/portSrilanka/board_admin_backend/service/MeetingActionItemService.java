package com.portSrilanka.board_admin_backend.service;
import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.ActionItemStatus;
import com.portSrilanka.board_admin_backend.exception.*;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;

@Service @RequiredArgsConstructor
public class MeetingActionItemService {
 private final MeetingActionItemRepository repository; private final MeetingRepository meetingRepository;
 private final MeetingParticipantRepository participantRepository; private final UserRepository userRepository; private final AuditService auditService; private final ActionItemEmailService actionItemEmailService;
 public List<ActionItemResponse> list(Long meetingId,String username,boolean manager){User u=user(username);meetingForUser(meetingId,u,manager);return repository.findByMeetingIdOrderByDueDateAscCreatedAtDesc(meetingId).stream().map(x->map(x,u,manager)).toList();}
 public ActionItemResponse create(Long meetingId,ActionItemRequest r,String username,boolean manager){User creator=user(username);Meeting meeting=meetingForUser(meetingId,creator,manager);if(r.getTitle()==null||r.getTitle().isBlank())throw new BadRequestException("Action item title is required");User assignee=userRepository.findById(r.getAssigneeUserId()).orElseThrow(()->new ResourceNotFoundException("Assignee not found"));if(participantRepository.findByMeetingIdAndUserId(meetingId,assignee.getId()).isEmpty())throw new BadRequestException("Assignee must be a meeting participant");MeetingActionItem item=repository.save(MeetingActionItem.builder().meeting(meeting).title(r.getTitle().trim()).description(clean(r.getDescription())).assignee(assignee).createdBy(creator).dueDate(r.getDueDate()).build());auditService.logInfo("ACTION_ITEM","CREATE",username,"Action item created: "+item.getTitle(),"DEVICE");actionItemEmailService.sendAssignmentEmail(item);return map(item,creator,manager);}
 public ActionItemResponse status(Long id,ActionItemStatusRequest r,String username,boolean manager){MeetingActionItem item=repository.findById(id).orElseThrow(()->new ResourceNotFoundException("Action item not found"));User u=user(username);meetingForUser(item.getMeeting().getId(),u,manager);if(!manager&&!item.getAssignee().getId().equals(u.getId()))throw new AccessDeniedException("Only the assignee can update this action item");if(r.getStatus()==null)throw new BadRequestException("Status is required");item.setStatus(r.getStatus());item.setCompletionNote(clean(r.getCompletionNote()));item=repository.save(item);auditService.logInfo("ACTION_ITEM","UPDATE_STATUS",username,"Action item "+id+" changed to "+r.getStatus(),"DEVICE");return map(item,u,manager);}
 public void delete(Long id,String username,boolean manager){MeetingActionItem item=repository.findById(id).orElseThrow(()->new ResourceNotFoundException("Action item not found"));if(!manager&&!item.getCreatedBy().getUsername().equals(username))throw new AccessDeniedException("Only its creator can delete this action item");repository.delete(item);auditService.logInfo("ACTION_ITEM","DELETE",username,"Action item "+id+" deleted","DEVICE");}
 private Meeting meetingForUser(Long id,User u,boolean manager){Meeting m=meetingRepository.findById(id).orElseThrow(()->new ResourceNotFoundException("Meeting not found"));if(!manager&&participantRepository.findByMeetingIdAndUserId(id,u.getId()).isEmpty())throw new AccessDeniedException("Meeting access denied");return m;}
 private User user(String n){return userRepository.findByUsername(n).orElseThrow(()->new ResourceNotFoundException("User not found"));}
 private String clean(String s){return s==null||s.isBlank()?null:s.trim();}
 private ActionItemResponse map(MeetingActionItem x,User u,boolean manager){return ActionItemResponse.builder().id(x.getId()).meetingId(x.getMeeting().getId()).title(x.getTitle()).description(x.getDescription()).assigneeUserId(x.getAssignee().getId()).assigneeUsername(x.getAssignee().getUsername()).createdByUsername(x.getCreatedBy().getUsername()).dueDate(x.getDueDate()).status(x.getStatus()).completionNote(x.getCompletionNote()).editableByCurrentUser(manager||x.getAssignee().getId().equals(u.getId())).createdAt(x.getCreatedAt()).updatedAt(x.getUpdatedAt()).build();}
}
