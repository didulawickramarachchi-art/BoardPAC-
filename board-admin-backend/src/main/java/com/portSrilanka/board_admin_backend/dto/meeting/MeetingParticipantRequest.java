package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Data;

@Data
public class MeetingParticipantRequest {
    private Long meetingId;
    private Long userId;
    private Integer displaySequence;
}
