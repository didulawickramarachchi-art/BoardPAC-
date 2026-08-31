package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.service.PaperReadStateService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/paper-read-states")
@RequiredArgsConstructor
public class PaperReadStateController {
    private final PaperReadStateService service;

    @GetMapping("/recent")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<java.util.List<RecentPaperResponse>> recent(Authentication authentication) {
        return ResponseEntity.ok(service.recent(authentication.getName()));
    }

    @GetMapping("/{paperId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<PaperReadStateResponse> get(
            @PathVariable Long paperId, Authentication authentication) {
        return ResponseEntity.ok(service.get(paperId, authentication.getName()));
    }

    @PutMapping("/{paperId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<PaperReadStateResponse> update(
            @PathVariable Long paperId,
            @RequestBody PaperReadStateRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(service.update(paperId, authentication.getName(), request));
    }
}
