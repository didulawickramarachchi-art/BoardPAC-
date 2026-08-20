package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.comment.*;
import com.portSrilanka.board_admin_backend.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping
    @PreAuthorize("(hasRole('SECRETARY') or hasRole('MEMBER')) and @accessProfileService.canComment(authentication.name)")
    public ResponseEntity<CommentResponse> create(@RequestBody CommentRequest request) {
        return ResponseEntity.ok(commentService.create(request));
    }

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<CommentResponse>> getByPaper(
            @PathVariable Long paperId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(commentService.getByPaper(paperId, authentication.getName()));
    }

    @GetMapping("/meeting/{meetingId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<CommentResponse>> getByMeeting(
            @PathVariable Long meetingId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(commentService.getByMeeting(meetingId, authentication.getName()));
    }

    @PostMapping("/{commentId}/reaction")
    @PreAuthorize("(hasRole('SECRETARY') or hasRole('MEMBER')) and @accessProfileService.canComment(authentication.name)")
    public ResponseEntity<CommentResponse> toggleReaction(
            @PathVariable Long commentId,
            @RequestBody ReactionRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(commentService.react(commentId, request.getReactionType(), authentication.getName()));
    }

    @PostMapping("/{commentId}/replies")
    @PreAuthorize("(hasRole('SECRETARY') or hasRole('MEMBER')) and @accessProfileService.canComment(authentication.name)")
    public ResponseEntity<CommentResponse> reply(
            @PathVariable Long commentId,
            @RequestBody CommentReplyRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(commentService.reply(commentId, request.getMessage(), authentication.getName()));
    }

    @PostMapping("/share")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> shareComment(@RequestBody ShareCommentRequest request) {
        return ResponseEntity.ok(commentService.shareComment(request));
    }
}
