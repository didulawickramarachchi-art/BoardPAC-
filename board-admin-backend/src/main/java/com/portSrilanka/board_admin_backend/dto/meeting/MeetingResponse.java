package com.portSrilanka.board_admin_backend.dto.meeting;

import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class MeetingResponse {
    private Long id;
    private String title;
    private MeetingType type;
    private MeetingStatus status;
    private LocalDateTime meetingDateTime;
    private LocalDateTime targetDateTime;
    private String location;
    private String description;
    private String categoryName;
    private Long subcategoryId;
    private String subcategoryName;
}
