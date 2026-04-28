package com.portSrilanka.board_admin_backend.dto.meeting;

import com.portSrilanka.board_admin_backend.enums.ParticipantStatus;
import lombok.Data;

@Data
public class ParticipantStatusUpdateRequest {
    private Long meetingId;
    private Long userId;
    private ParticipantStatus participantStatus;
    private String statusReason;
}
