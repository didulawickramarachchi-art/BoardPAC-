package com.portSrilanka.board_admin_backend.dto.meeting;

import com.portSrilanka.board_admin_backend.enums.ParticipantStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class MeetingParticipantResponse {
    private Long id;
    private Long userId;
    private String username;
    private ParticipantStatus participantStatus;
    private String statusReason;
    private Integer displaySequence;
}
