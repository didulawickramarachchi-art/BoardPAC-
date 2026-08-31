package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.service.MeetingWorkspaceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/meeting-workspace") @RequiredArgsConstructor
public class MeetingWorkspaceController {
    private final MeetingWorkspaceService service;

    @GetMapping("/{meetingId}/notes")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PrivateMeetingNoteResponse>> notes(
            @PathVariable Long meetingId, Authentication authentication) {
        return ResponseEntity.ok(service.notes(meetingId, authentication.getName()));
    }

    @PostMapping("/{meetingId}/notes")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<PrivateMeetingNoteResponse> addNote(
            @PathVariable Long meetingId, @RequestBody MeetingNoteRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(service.addNote(meetingId, request.getNoteText(), authentication.getName()));
    }

    @PutMapping("/notes/{noteId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<PrivateMeetingNoteResponse> updateNote(
            @PathVariable Long noteId, @RequestBody MeetingNoteRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(service.updateNote(noteId, request.getNoteText(), authentication.getName()));
    }

    @DeleteMapping("/notes/{noteId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<Void> deleteNote(@PathVariable Long noteId, Authentication authentication) {
        service.deleteNote(noteId, authentication.getName());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{meetingId}/minutes")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<MeetingMinutesResponse>> minutes(
            @PathVariable Long meetingId, Authentication authentication) {
        boolean secretary = authentication.getAuthorities().stream()
                .anyMatch(authority -> authority.getAuthority().equals("ROLE_SECRETARY"));
        return ResponseEntity.ok(service.minutes(meetingId, authentication.getName(), secretary));
    }

    @PostMapping("/{meetingId}/minutes")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingMinutesResponse> createMinutes(
            @PathVariable Long meetingId, @RequestBody MeetingMinutesRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(service.createMinutes(meetingId, request.getContent(), authentication.getName()));
    }

    @PutMapping("/minutes/{minutesId}/{action}")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingMinutesResponse> transition(
            @PathVariable Long minutesId, @PathVariable String action,
            @RequestBody(required = false) MeetingMinutesRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(service.transition(minutesId, action,
                request == null ? null : request.getReviewComment(), authentication.getName()));
    }
}
