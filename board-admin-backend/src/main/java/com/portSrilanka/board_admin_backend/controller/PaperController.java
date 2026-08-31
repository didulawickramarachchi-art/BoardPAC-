package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.service.PaperService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/papers")
@RequiredArgsConstructor
public class PaperController {

    private final PaperService paperService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY') and @accessProfileService.canUploadPapers(authentication.name)")
    public ResponseEntity<PaperResponse> create(@RequestBody PaperRequest request, Authentication authentication) {
        return ResponseEntity.ok(paperService.create(request, authentication.getName()));
    }

    @GetMapping
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PaperResponse>> getAll() {
        return ResponseEntity.ok(paperService.getAll());
    }

    @GetMapping("/meeting/{meetingId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PaperResponse>> getByMeeting(@PathVariable Long meetingId) {
        return ResponseEntity.ok(paperService.getByMeeting(meetingId));
    }

    @GetMapping("/agenda-item/{agendaItemId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PaperResponse>> getByAgendaItem(@PathVariable Long agendaItemId) {
        return ResponseEntity.ok(paperService.getByAgendaItem(agendaItemId));
    }

    @PutMapping("/{paperId}/read")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<String> markRead(
            @PathVariable Long paperId, Authentication authentication) {
        return ResponseEntity.ok(paperService.markRead(paperId, authentication.getName()));
    }

    @GetMapping("/{paperId}/versions")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PaperResponse>> versions(@PathVariable Long paperId, Authentication authentication) {
        boolean secretary = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SECRETARY"));
        return ResponseEntity.ok(paperService.versionHistory(paperId, authentication.getName(), secretary));
    }

    @PostMapping("/{paperId}/versions")
    @PreAuthorize("hasRole('SECRETARY') and @accessProfileService.canUploadPapers(authentication.name)")
    public ResponseEntity<PaperResponse> revise(@PathVariable Long paperId, @RequestBody PaperRevisionRequest request, Authentication authentication) {
        return ResponseEntity.ok(paperService.createRevision(paperId, request, authentication.getName()));
    }

    @PostMapping("/share")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> sharePaper(@RequestBody SharePaperRequest request) {
        return ResponseEntity.ok(paperService.sharePaper(request));
    }
}
