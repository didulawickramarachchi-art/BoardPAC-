package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Data;

@Data
public class MeetingNoteRequest {
    private Long meetingId;
    private Long userId;
    private String noteText;
}