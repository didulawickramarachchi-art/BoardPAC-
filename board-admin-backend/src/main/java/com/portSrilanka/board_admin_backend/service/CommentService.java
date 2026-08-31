package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.comment.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.CommentVisibility;
import com.portSrilanka.board_admin_backend.enums.ReactionType;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class CommentService {
    private final MeetingRepository meetingRepository; private final PaperRepository paperRepository;
    private final UserRepository userRepository; private final CommentRepository commentRepository;
    private final CommentShareRepository commentShareRepository; private final CommentReactionRepository commentReactionRepository;
    private final CommentReplyRepository commentReplyRepository; private final AuditService auditService;
    private final NotificationService notificationService;

    public CommentResponse create(CommentRequest r, String username) {
        Meeting meeting = r.getMeetingId() == null ? null : meetingRepository.findById(r.getMeetingId()).orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        Paper paper = r.getPaperId() == null ? null : paperRepository.findById(r.getPaperId()).orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        if (meeting == null && paper != null) meeting = paper.getMeeting();
        if (meeting == null) throw new BadRequestException("A meeting or paper is required");
        requireText(r.getCommentText()); User owner = findUser(username); CommentVisibility visibility = visibility(r.getVisibility());
        Comment saved = commentRepository.save(Comment.builder().meeting(meeting).paper(paper).createdBy(owner)
                .commentText(r.getCommentText().trim()).annotated(r.isAnnotated()).visibility(visibility)
                .pageNumber(r.getPageNumber()).recipients(recipients(r, visibility, meeting, owner)).build());
        auditService.logInfo("COMMENT", "CREATE_COMMENT", username, "Comment added", "DEVICE");
        return map(saved, owner.getId());
    }

    public CommentResponse update(Long id, CommentRequest r, String username) {
        Comment c = owned(id, username); requireText(r.getCommentText());
        Meeting meeting = c.getMeeting() != null ? c.getMeeting() : c.getPaper().getMeeting(); CommentVisibility visibility = visibility(r.getVisibility());
        c.setCommentText(r.getCommentText().trim()); c.setAnnotated(r.isAnnotated()); c.setPageNumber(r.getPageNumber());
        c.setVisibility(visibility); c.setRecipients(recipients(r, visibility, meeting, c.getCreatedBy()));
        c = commentRepository.save(c); auditService.logInfo("COMMENT", "UPDATE_COMMENT", username, "Comment " + id + " updated", "DEVICE");
        return map(c, c.getCreatedBy().getId());
    }

    public void delete(Long id, String username) { commentRepository.delete(owned(id, username)); auditService.logInfo("COMMENT", "DELETE_COMMENT", username, "Comment " + id + " deleted", "DEVICE"); }
    public List<CommentResponse> getByPaper(Long id, String username) { User u=findUser(username); return commentRepository.findByPaperId(id).stream().filter(c->canView(c,u)).map(c->map(c,u.getId())).toList(); }
    public List<CommentResponse> getByMeeting(Long id, String username) { User u=findUser(username); return commentRepository.findByMeetingId(id).stream().filter(c->canView(c,u)).map(c->map(c,u.getId())).toList(); }

    public CommentResponse react(Long id, ReactionType type, String username) {
        Comment c=findComment(id); User u=findUser(username); requireVisible(c,u);
        CommentReaction old=commentReactionRepository.findByCommentIdAndUserId(id,u.getId()).orElse(null);
        if(old!=null&&old.getReactionType()==type) commentReactionRepository.delete(old); else if(old!=null){old.setReactionType(type);commentReactionRepository.save(old);} else commentReactionRepository.save(CommentReaction.builder().comment(c).user(u).reactionType(type).build());
        return map(c,u.getId());
    }
    public CommentResponse reply(Long id,String message,String username){Comment c=findComment(id);User u=findUser(username);requireVisible(c,u);requireText(message);commentReplyRepository.save(CommentReply.builder().comment(c).createdBy(u).replyText(message.trim()).build());return map(c,u.getId());}
    public String shareComment(ShareCommentRequest r){Comment c=findComment(r.getCommentId());User from=userRepository.findById(r.getSharedByUserId()).orElseThrow(()->new ResourceNotFoundException("Shared by user not found"));User to=userRepository.findById(r.getSharedToUserId()).orElseThrow(()->new ResourceNotFoundException("Shared to user not found"));commentShareRepository.save(CommentShare.builder().comment(c).sharedBy(from).sharedTo(to).build());notificationService.notifyCommentShared(to,from.getUsername(),c.getPaper()==null?null:c.getPaper().getId(),c.getId());auditService.logInfo("COMMENT","SHARE_COMMENT",from.getUsername(),"Comment shared to "+to.getUsername(),"DEVICE");return "Comment shared successfully";}

    private User findUser(String n){return userRepository.findByUsername(n).orElseThrow(()->new ResourceNotFoundException("User not found"));}
    private Comment findComment(Long id){return commentRepository.findById(id).orElseThrow(()->new ResourceNotFoundException("Comment not found"));}
    private Comment owned(Long id,String n){Comment c=findComment(id);if(!c.getCreatedBy().getUsername().equals(n))throw new AccessDeniedException("Only the comment owner can change it");return c;}
    private void requireText(String s){if(s==null||s.trim().isEmpty())throw new BadRequestException("Text is required");}
    private CommentVisibility visibility(String s){if(s==null||s.isBlank())return CommentVisibility.ALL_PARTICIPANTS;try{return CommentVisibility.valueOf(s.trim().toUpperCase());}catch(IllegalArgumentException e){throw new BadRequestException("Invalid comment visibility");}}
    private Set<User> recipients(CommentRequest r,CommentVisibility v,Meeting m,User owner){if(v!=CommentVisibility.SELECTED_PARTICIPANTS)return new HashSet<>();Set<Long> ids=r.getSelectedUserIds()==null?Set.of():r.getSelectedUserIds();if(ids.isEmpty())throw new BadRequestException("Select at least one participant");Set<Long> valid=m.getParticipants().stream().map(p->p.getUser().getId()).collect(Collectors.toSet());if(!valid.containsAll(ids))throw new BadRequestException("Recipients must be meeting participants");Set<User> users=new HashSet<>(userRepository.findAllById(ids));if(users.size()!=ids.size())throw new BadRequestException("One or more recipients were not found");users.removeIf(u->u.getId().equals(owner.getId()));return users;}
    private boolean canView(Comment c,User u){return c.getCreatedBy().getId().equals(u.getId())||c.getVisibility()==CommentVisibility.ALL_PARTICIPANTS||c.getVisibility()==CommentVisibility.SELECTED_PARTICIPANTS&&c.getRecipients().stream().anyMatch(x->x.getId().equals(u.getId()));}
    private void requireVisible(Comment c,User u){if(!canView(c,u))throw new AccessDeniedException("Comment is private");}

    private CommentResponse map(Comment c,Long userId){List<CommentReaction> reactions=commentReactionRepository.findByCommentId(c.getId());Map<String,Long> counts=new HashMap<>();for(ReactionType t:ReactionType.values())counts.put(t.name(),reactions.stream().filter(r->r.getReactionType()==t).count());CommentReaction mine=reactions.stream().filter(r->r.getUser().getId().equals(userId)).findFirst().orElse(null);return CommentResponse.builder().id(c.getId()).createdByUserId(c.getCreatedBy().getId()).createdByUsername(c.getCreatedBy().getUsername()).createdByProfilePictureUrl(c.getCreatedBy().getProfilePictureUrl()).commentText(c.getCommentText()).annotated(c.isAnnotated()).visibility(c.getVisibility().name()).pageNumber(c.getPageNumber()).ownedByCurrentUser(c.getCreatedBy().getId().equals(userId)).selectedUserIds(c.getRecipients().stream().map(User::getId).toList()).createdAt(c.getCreatedAt()).updatedAt(c.getUpdatedAt()).reactionCount(reactions.size()).reactedByCurrentUser(mine!=null).currentReaction(mine==null?null:mine.getReactionType().name()).reactionCounts(counts).replies(commentReplyRepository.findByCommentIdOrderByCreatedAtAsc(c.getId()).stream().map(x->CommentResponse.Reply.builder().id(x.getId()).createdByUserId(x.getCreatedBy().getId()).createdByUsername(x.getCreatedBy().getUsername()).createdByProfilePictureUrl(x.getCreatedBy().getProfilePictureUrl()).message(x.getReplyText()).createdAt(x.getCreatedAt()).build()).toList()).build();}
}
