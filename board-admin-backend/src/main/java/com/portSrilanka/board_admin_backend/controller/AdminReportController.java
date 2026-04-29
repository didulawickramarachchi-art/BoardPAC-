package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.service.AdminReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin-reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public class AdminReportController {

    private final AdminReportService adminReportService;

    @GetMapping("/user-category")
    public ResponseEntity<List<UserCategoryReportResponse>> userCategoryReport() {
        return ResponseEntity.ok(adminReportService.userCategoryReport());
    }

    @GetMapping("/license-utilization")
    public ResponseEntity<LicenseUtilizationResponse> licenseUtilization() {
        return ResponseEntity.ok(adminReportService.licenseUtilization());
    }

    @GetMapping("/pending-approvals")
    public ResponseEntity<List<PendingApprovalReportResponse>> pendingApprovals() {
        return ResponseEntity.ok(adminReportService.pendingApprovalReport());
    }
}