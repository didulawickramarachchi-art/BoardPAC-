package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.service.MeetingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/meetings")
@RequiredArgsConstructor
public class MeetingController {

    private final MeetingService meetingService;

    @PostMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<MeetingResponse> create(@RequestBody MeetingRequest request) {
        return ResponseEntity.ok(meetingService.create(request));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<MeetingResponse>> getAll() {
        return ResponseEntity.ok(meetingService.getAll());
    }

    @GetMapping("/subcategory/{subcategoryId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<MeetingResponse>> getBySubcategory(@PathVariable Long subcategoryId) {
        return ResponseEntity.ok(meetingService.getBySubcategory(subcategoryId));
    }

    @PutMapping("/{meetingId}/open")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<MeetingResponse> open(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.openMeeting(meetingId));
    }

    @PutMapping("/{meetingId}/close")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<MeetingResponse> close(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.closeMeeting(meetingId));
    }

    @PostMapping("/participants")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<MeetingParticipantResponse> addParticipant(@RequestBody MeetingParticipantRequest request) {
        return ResponseEntity.ok(meetingService.addParticipant(request));
    }

    @GetMapping("/{meetingId}/participants")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<MeetingParticipantResponse>> getParticipants(@PathVariable Long meetingId) {
        return ResponseEntity.ok(meetingService.getParticipants(meetingId));
    }

    @PutMapping("/participants/status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MeetingParticipantResponse> updateParticipantStatus(
            @RequestBody ParticipantStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(meetingService.updateParticipantStatus(request));
    }

    @PostMapping("/notes")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<String> addNote(@RequestBody MeetingNoteRequest request) {
        return ResponseEntity.ok(meetingService.addMeetingNote(request));
    }
}
