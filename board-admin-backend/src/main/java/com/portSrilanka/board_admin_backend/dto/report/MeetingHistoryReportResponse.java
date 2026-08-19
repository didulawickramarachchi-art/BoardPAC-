package com.portSrilanka.board_admin_backend.dto.report;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class MeetingHistoryReportResponse {
    private Long id;
    private String title;
    private String status;
    private LocalDateTime meetingDateTime;
    private String location;
    private String description;
    private Long categoryId;
    private String categoryName;
    private Long subcategoryId;
    private String subcategoryName;
    private List<PaperSummary> papers;

    @Data
    @Builder
    public static class PaperSummary {
        private Long id;
        private String title;
        private String paperType;
        private String referenceNumber;
        private Integer versionNumber;
    }
}
