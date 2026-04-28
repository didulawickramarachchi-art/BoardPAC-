package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/login-history")
    public ResponseEntity<List<LoginHistoryResponse>> getLoginHistory() {
        return ResponseEntity.ok(reportService.getLoginHistory());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLogResponse>> getAuditLogs() {
        return ResponseEntity.ok(reportService.getAuditLogs());
    }
}