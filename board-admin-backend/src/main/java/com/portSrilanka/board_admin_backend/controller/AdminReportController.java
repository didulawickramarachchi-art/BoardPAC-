package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.service.AdminReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.List;

@RestController
@RequestMapping("/api/admin-reports")
@RequiredArgsConstructor
public class AdminReportController {

    private final AdminReportService adminReportService;

    @GetMapping("/user-category")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserCategoryReportResponse>> userCategoryReport() {
        return ResponseEntity.ok(adminReportService.userCategoryReport());
    }

    @GetMapping("/license-utilization")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LicenseUtilizationResponse> licenseUtilization() {
        return ResponseEntity.ok(adminReportService.licenseUtilization());
    }

    @GetMapping("/pending-approvals")
    @PreAuthorize("hasRole('ADMIN') or @accessProfileService.canApprove(authentication.name)")
    public ResponseEntity<List<PendingApprovalReportResponse>> pendingApprovals(Authentication authentication) {
        boolean admin = authentication.getAuthorities().stream()
                .anyMatch(authority -> authority.getAuthority().equals("ROLE_ADMIN"));
        return ResponseEntity.ok(adminReportService.pendingApprovalReport(authentication.getName(), admin));
    }
}
