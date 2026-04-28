package com.portSrilanka.board_admin_backend.dto.agenda;

import lombok.Data;

@Data
public class AgendaSectionRequest {
    private Long meetingId;
    private String title;
    private String numberLabel;
    private Integer displayOrder;
}
