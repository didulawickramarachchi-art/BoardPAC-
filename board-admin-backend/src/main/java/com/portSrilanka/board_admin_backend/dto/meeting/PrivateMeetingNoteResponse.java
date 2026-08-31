package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data @Builder
public class PrivateMeetingNoteResponse {
    private Long id;
    private Long meetingId;
    private String noteText;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
