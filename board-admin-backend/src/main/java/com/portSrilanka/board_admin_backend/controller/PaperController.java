package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.service.PaperService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/papers")
@RequiredArgsConstructor
public class PaperController {

    private final PaperService paperService;

    @PostMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<PaperResponse> create(@RequestBody PaperRequest request) {
        return ResponseEntity.ok(paperService.create(request));
    }

    @GetMapping("/meeting/{meetingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<PaperResponse>> getByMeeting(@PathVariable Long meetingId) {
        return ResponseEntity.ok(paperService.getByMeeting(meetingId));
    }

    @GetMapping("/agenda-item/{agendaItemId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<PaperResponse>> getByAgendaItem(@PathVariable Long agendaItemId) {
        return ResponseEntity.ok(paperService.getByAgendaItem(agendaItemId));
    }

    @PutMapping("/{paperId}/read/{userId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<String> markRead(@PathVariable Long paperId, @PathVariable Long userId) {
        return ResponseEntity.ok(paperService.markRead(paperId, userId));
    }

    @PostMapping("/share")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<String> sharePaper(@RequestBody SharePaperRequest request) {
        return ResponseEntity.ok(paperService.sharePaper(request));
    }
}