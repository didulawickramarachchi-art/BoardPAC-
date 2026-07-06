package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.comment.*;
import com.portSrilanka.board_admin_backend.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<CommentResponse> create(@RequestBody CommentRequest request) {
        return ResponseEntity.ok(commentService.create(request));
    }

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<CommentResponse>> getByPaper(@PathVariable Long paperId) {
        return ResponseEntity.ok(commentService.getByPaper(paperId));
    }

    @GetMapping("/meeting/{meetingId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<CommentResponse>> getByMeeting(@PathVariable Long meetingId) {
        return ResponseEntity.ok(commentService.getByMeeting(meetingId));
    }

    @PostMapping("/share")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> shareComment(@RequestBody ShareCommentRequest request) {
        return ResponseEntity.ok(commentService.shareComment(request));
    }
}
