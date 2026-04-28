package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.comment.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final MeetingRepository meetingRepository;
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final CommentRepository commentRepository;
    private final CommentShareRepository commentShareRepository;
    private final AuditService auditService;

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

    public List<CommentResponse> getByPaper(Long paperId) {
        return commentRepository.findByPaperId(paperId).stream()
                .map(this::mapComment)
                .toList();
    }

    public List<CommentResponse> getByMeeting(Long meetingId) {
        return commentRepository.findByMeetingId(meetingId).stream()
                .map(this::mapComment)
                .toList();
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

        auditService.logInfo("COMMENT", "SHARE_COMMENT",
                sharedBy.getUsername(),
                "Comment shared to " + sharedTo.getUsername(), "DEVICE");

        return "Comment shared successfully";
    }

    private CommentResponse mapComment(Comment comment) {
        return CommentResponse.builder()
                .id(comment.getId())
                .createdByUsername(comment.getCreatedBy().getUsername())
                .commentText(comment.getCommentText())
                .annotated(comment.isAnnotated())
                .build();
    }
}
