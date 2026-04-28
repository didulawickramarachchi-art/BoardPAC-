package com.portSrilanka.board_admin_backend.dto.issue;

import lombok.Data;

import java.time.LocalDate;

@Data
public class IssueReportRequest {
    private LocalDate issueOccurredDate;
    private String issueDescription;
    private String username;
    private String screenshotPath;
    private boolean attachLogFiles;
    private boolean attachProductSettings;
    private boolean attachErrorData;
    private String otherResources;
}
