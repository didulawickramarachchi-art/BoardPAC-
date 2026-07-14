package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.comment.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.EnumMap;
import java.util.Map;
import com.portSrilanka.board_admin_backend.enums.ReactionType;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final MeetingRepository meetingRepository;
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final CommentRepository commentRepository;
    private final CommentShareRepository commentShareRepository;
    private final CommentReactionRepository commentReactionRepository;
    private final AuditService auditService;

    // ✅ NEW INJECTION
    private final NotificationService notificationService;

    public CommentResponse create(CommentRequest request) {
        Meeting meeting = null;
        Paper paper = null;

        if (request.getMeetingId() != null) {
            meeting = meetingRepository.findById(request.getMeetingId())
                    .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        }

        if (request.getPaperId() != null) {
            paper = paperRepository.findById(request.getPaperId())
                    .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        }

        User createdBy = userRepository.findById(request.getCreatedByUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Comment comment = Comment.builder()
                .meeting(meeting)
                .paper(paper)
                .createdBy(createdBy)
                .commentText(request.getCommentText())
                .annotated(request.isAnnotated())
                .build();

        comment = commentRepository.save(comment);

        auditService.logInfo("COMMENT", "CREATE_COMMENT",
                createdBy.getUsername(),
                "Comment added", "DEVICE");

        return CommentResponse.builder()
                .id(comment.getId())
                .createdByUsername(createdBy.getUsername())
                .commentText(comment.getCommentText())
                .annotated(comment.isAnnotated())
                .build();
    }

    public List<CommentResponse> getByPaper(Long paperId, String username) {
        User currentUser = findUser(username);
        return commentRepository.findByPaperId(paperId).stream()
                .map(comment -> mapComment(comment, currentUser.getId()))
                .toList();
    }

    public List<CommentResponse> getByMeeting(Long meetingId, String username) {
        User currentUser = findUser(username);
        return commentRepository.findByMeetingId(meetingId).stream()
                .map(comment -> mapComment(comment, currentUser.getId()))
                .toList();
    }

    public CommentResponse react(Long commentId, ReactionType reactionType, String username) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));
        User user = findUser(username);

        CommentReaction existing = commentReactionRepository
                .findByCommentIdAndUserId(commentId, user.getId()).orElse(null);
        if (existing != null && existing.getReactionType() == reactionType) {
            commentReactionRepository.delete(existing);
        } else if (existing != null) {
            existing.setReactionType(reactionType);
            commentReactionRepository.save(existing);
        } else {
            commentReactionRepository.save(CommentReaction.builder()
                    .comment(comment).user(user).reactionType(reactionType).build());
        }
        return mapComment(comment, user.getId());
    }

    public String shareComment(ShareCommentRequest request) {

        Comment comment = commentRepository.findById(request.getCommentId())
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));

        User sharedBy = userRepository.findById(request.getSharedByUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Shared by user not found"));

        User sharedTo = userRepository.findById(request.getSharedToUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Shared to user not found"));

        commentShareRepository.save(
                CommentShare.builder()
                        .comment(comment)
                        .sharedBy(sharedBy)
                        .sharedTo(sharedTo)
                        .build()
        );

        // ✅ NEW: Notification after share
        notificationService.notifyCommentShared(
                sharedTo,
                sharedBy.getUsername()
        );

        auditService.logInfo("COMMENT", "SHARE_COMMENT",
                sharedBy.getUsername(),
                "Comment shared to " + sharedTo.getUsername(), "DEVICE");

        return "Comment shared successfully";
    }

    private User findUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private CommentResponse mapComment(Comment comment, Long currentUserId) {
        List<CommentReaction> reactions = commentReactionRepository.findByCommentId(comment.getId());
        Map<String, Long> counts = new java.util.HashMap<>();
        for (ReactionType type : ReactionType.values()) {
            counts.put(type.name(), reactions.stream()
                    .filter(reaction -> reaction.getReactionType() == type).count());
        }
        CommentReaction currentReaction = reactions.stream()
                .filter(reaction -> reaction.getUser().getId().equals(currentUserId))
                .findFirst().orElse(null);
        return CommentResponse.builder()
                .id(comment.getId())
                .createdByUsername(comment.getCreatedBy().getUsername())
                .commentText(comment.getCommentText())
                .annotated(comment.isAnnotated())
                .createdAt(comment.getCreatedAt())
                .reactionCount(commentReactionRepository.countByCommentId(comment.getId()))
                .reactedByCurrentUser(commentReactionRepository
                        .findByCommentIdAndUserId(comment.getId(), currentUserId)
                        .isPresent())
                .currentReaction(currentReaction != null ? currentReaction.getReactionType().name() : null)
                .reactionCounts(counts)
                .build();
    }
}
