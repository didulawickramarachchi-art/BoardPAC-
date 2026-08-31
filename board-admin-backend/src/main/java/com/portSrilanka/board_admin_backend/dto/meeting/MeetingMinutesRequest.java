package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Data;

@Data
public class MeetingMinutesRequest {
    private String content;
    private String reviewComment;
}
