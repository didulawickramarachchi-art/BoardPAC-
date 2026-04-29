package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.agenda.*;
import com.portSrilanka.board_admin_backend.service.AgendaService;
import com.portSrilanka.board_admin_backend.service.AgendaSharingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/agendas")
@RequiredArgsConstructor
public class AgendaController {

    private final AgendaService agendaService;
    private final AgendaSharingService agendaSharingService;

    @PostMapping("/sections")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<AgendaSectionResponse> createSection(@RequestBody AgendaSectionRequest request) {
        return ResponseEntity.ok(agendaService.createSection(request));
    }

    @GetMapping("/sections/{meetingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<AgendaSectionResponse>> getSections(@PathVariable Long meetingId) {
        return ResponseEntity.ok(agendaService.getSections(meetingId));
    }

    @PostMapping("/items")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<AgendaItemResponse> createItem(@RequestBody AgendaItemRequest request) {
        return ResponseEntity.ok(agendaService.createItem(request));
    }

    @GetMapping("/items/{meetingId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<AgendaItemResponse>> getItems(@PathVariable Long meetingId) {
        return ResponseEntity.ok(agendaService.getItems(meetingId));
    }

    @PostMapping("/share")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<SharedAgendaItemResponse> shareAgendaItem(@RequestBody ShareAgendaItemRequest request) {
        return ResponseEntity.ok(agendaSharingService.shareAgendaItem(request));
    }

    @GetMapping("/shared/subcategory/{subcategoryId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<SharedAgendaItemResponse>> getSharedToSubcategory(@PathVariable Long subcategoryId) {
        return ResponseEntity.ok(agendaSharingService.getSharedToSubcategory(subcategoryId));
    }
}