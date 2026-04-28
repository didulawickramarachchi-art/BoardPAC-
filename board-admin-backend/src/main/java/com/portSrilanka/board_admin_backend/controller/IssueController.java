package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.issue.IssueReportRequest;
import com.portSrilanka.board_admin_backend.service.IssueService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/issues")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public class IssueController {

    private final IssueService issueService;

    @PostMapping
    public ResponseEntity<String> reportIssue(@RequestBody IssueReportRequest request) {
        return ResponseEntity.ok(issueService.reportIssue(request));
    }
}
