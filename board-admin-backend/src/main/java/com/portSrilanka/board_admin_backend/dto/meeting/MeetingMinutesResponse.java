package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data @Builder
public class MeetingMinutesResponse {
    private Long id;
    private Long meetingId;
    private Integer versionNumber;
    private String content;
    private String status;
    private String createdBy;
    private String reviewedBy;
    private String reviewComment;
    private LocalDateTime publishedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
