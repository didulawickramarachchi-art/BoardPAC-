package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.service.MeetingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/meetings")
@RequiredArgsConstructor
public class MeetingController {

    private final MeetingService meetingService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingResponse> create(
            @RequestBody MeetingRequest request,
            Authentication authentication
    ) {
        return ResponseEntity.ok(meetingService.create(request, authentication.getName()));
    }

    @GetMapping
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<MeetingResponse>> getAll() {
        return ResponseEntity.ok(meetingService.getAll());
    }

    @GetMapping("/subcategory/{subcategoryId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<MeetingResponse>> getBySubcategory(@PathVariable Long subcategoryId) {
        return ResponseEntity.ok(meetingService.getBySubcategory(subcategoryId));
    }

    @PutMapping("/{meetingId}/open")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingResponse> open(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.openMeeting(meetingId));
    }

    @PutMapping("/{meetingId}/close")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingResponse> close(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.closeMeeting(meetingId));
    }

    @PostMapping("/participants")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<MeetingParticipantResponse> addParticipant(@RequestBody MeetingParticipantRequest request) {
        return ResponseEntity.ok(meetingService.addParticipant(request));
    }

    @GetMapping("/{meetingId}/participants")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<MeetingParticipantResponse>> getParticipants(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.getParticipants(meetingId));
    }

    @PutMapping("/participants/status")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<MeetingParticipantResponse> updateParticipantStatus(
            @RequestBody ParticipantStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(meetingService.updateParticipantStatus(request));
    }

    @PostMapping("/notes")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<String> addNote(@RequestBody MeetingNoteRequest request) {
        return ResponseEntity.ok(meetingService.addMeetingNote(request));
    }

    @DeleteMapping("/{meetingId}")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> deleteMeeting(
            @PathVariable Long meetingId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(meetingService.deleteMeeting(meetingId, authentication.getName()));
    }
}
