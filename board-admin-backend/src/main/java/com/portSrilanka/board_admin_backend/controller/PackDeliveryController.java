package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.PackDeliveryResponse;
import com.portSrilanka.board_admin_backend.service.PackDeliveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.List;

@RestController
@RequestMapping("/api/pack-delivery")
@RequiredArgsConstructor
public class PackDeliveryController {

    private final PackDeliveryService packDeliveryService;

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<List<PackDeliveryResponse>> getByPaper(@PathVariable Long paperId) {
        return ResponseEntity.ok(packDeliveryService.getByPaper(paperId));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<PackDeliveryResponse>> getByUser(@PathVariable Long userId, Authentication authentication) {
        boolean secretary = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SECRETARY"));
        return ResponseEntity.ok(packDeliveryService.getByUser(userId, authentication.getName(), secretary));
    }

    @PostMapping("/paper/{paperId}/downloaded")
    @PreAuthorize("hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<Void> downloaded(@PathVariable Long paperId, Authentication authentication) {
        packDeliveryService.markDownloaded(paperId, authentication.getName());
        return ResponseEntity.noContent().build();
    }
}
