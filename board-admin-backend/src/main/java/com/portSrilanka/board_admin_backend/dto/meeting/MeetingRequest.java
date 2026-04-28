package com.portSrilanka.board_admin_backend.dto.meeting;

import com.portSrilanka.board_admin_backend.enums.MeetingType;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class MeetingRequest {
    private String title;
    private MeetingType type;
    private LocalDateTime meetingDateTime;
    private LocalDateTime targetDateTime;
    private String location;
    private String description;
    private Long categoryId;
    private Long subcategoryId;
    private Long createdByUserId;
}
