package com.portSrilanka.board_admin_backend.dto.dashboard;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class DashboardSummaryResponse {
    private long totalMeetings;
    private long totalCirculars;
    private long pendingApprovals;
    private long unreadPapers;
    private long sharedComments;
    private long sharedDocuments;
    private String upcomingMeetingTitle;
    private LocalDateTime upcomingMeetingDateTime;
    private String upcomingMeetingLocation;
    private String upcomingMeetingDaysText;
}
