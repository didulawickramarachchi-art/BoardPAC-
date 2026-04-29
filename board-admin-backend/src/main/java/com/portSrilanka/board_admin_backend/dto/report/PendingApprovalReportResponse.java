package com.portSrilanka.board_admin_backend.dto.report;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PendingApprovalReportResponse {
    private Long paperId;
    private String paperTitle;
    private Long userId;
    private String username;
    private String meetingTitle;
}
