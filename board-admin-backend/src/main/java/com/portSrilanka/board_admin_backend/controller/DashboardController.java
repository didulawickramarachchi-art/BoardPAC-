package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.dashboard.DashboardSummaryResponse;
import com.portSrilanka.board_admin_backend.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/summary/{userId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<DashboardSummaryResponse> getSummary(
            @PathVariable Long userId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                dashboardService.getSummaryForUser(userId, authentication.getName())
        );
    }
}
