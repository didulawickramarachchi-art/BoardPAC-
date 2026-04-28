package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.issue.IssueReportRequest;
import com.portSrilanka.board_admin_backend.entity.IssueReport;
import com.portSrilanka.board_admin_backend.repository.IssueReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class IssueService {

    private final IssueReportRepository issueReportRepository;
    private final AuditService auditService;

    public String reportIssue(IssueReportRequest request) {
        IssueReport issue = IssueReport.builder()
                .issueOccurredDate(request.getIssueOccurredDate())
                .issueDescription(request.getIssueDescription())
                .username(request.getUsername())
                .screenshotPath(request.getScreenshotPath())
                .attachLogFiles(request.isAttachLogFiles())
                .attachProductSettings(request.isAttachProductSettings())
                .attachErrorData(request.isAttachErrorData())
                .otherResources(request.getOtherResources())
                .build();

        issueReportRepository.save(issue);

        auditService.logInfo("ISSUE", "REPORT_ISSUE",
                request.getUsername(), request.getIssueDescription(), "WEB");

        return "Issue reported successfully";
    }
}