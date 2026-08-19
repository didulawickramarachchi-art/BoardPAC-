package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.MeetingHistoryReportResponse;
import com.portSrilanka.board_admin_backend.service.MeetingHistoryReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/meeting-history-report")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SECRETARY')")
public class MeetingHistoryReportController {
    private final MeetingHistoryReportService reportService;

    @GetMapping
    public ResponseEntity<List<MeetingHistoryReportResponse>> report(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long subcategoryId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(reportService.getReport(categoryId, subcategoryId, from, to));
    }

    @GetMapping(value = "/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> pdf(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long subcategoryId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=meeting-history-report.pdf")
                .body(reportService.generatePdf(categoryId, subcategoryId, from, to));
    }
}
