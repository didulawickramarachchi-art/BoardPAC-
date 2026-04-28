package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.common.PageResponse;
import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.service.CsvExportService;
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
    private final CsvExportService csvExportService;

    @GetMapping("/login-history")
    public ResponseEntity<List<LoginHistoryResponse>> getLoginHistory() {
        return ResponseEntity.ok(reportService.getLoginHistory());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLogResponse>> getAuditLogs() {
        return ResponseEntity.ok(reportService.getAuditLogs());
    }
    @GetMapping("/login-history/paged")
    public ResponseEntity<PageResponse<LoginHistoryResponse>> getLoginHistoryPaged(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(required = false) String username
) {
    return ResponseEntity.ok(reportService.getLoginHistoryPaged(page, size, username));
}

@GetMapping("/audit-logs/paged")
public ResponseEntity<PageResponse<AuditLogResponse>> getAuditLogsPaged(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(required = false) String username
) {
    return ResponseEntity.ok(reportService.getAuditLogsPaged(page, size, username));
}
@GetMapping(value = "/login-history/export", produces = "text/csv")
public ResponseEntity<String> exportLoginHistoryCsv() {
    return ResponseEntity.ok()
            .header("Content-Disposition", "attachment; filename=login-history.csv")
            .body(csvExportService.exportLoginHistoryCsv());
}

@GetMapping(value = "/audit-logs/export", produces = "text/csv")
public ResponseEntity<String> exportAuditLogsCsv() {
    return ResponseEntity.ok()
            .header("Content-Disposition", "attachment; filename=audit-logs.csv")
            .body(csvExportService.exportAuditLogsCsv());
}
}
