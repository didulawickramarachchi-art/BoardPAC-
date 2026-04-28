package com.portSrilanka.board_admin_backend.dto.agenda;

import com.portSrilanka.board_admin_backend.enums.AgendaItemType;
import lombok.Data;

@Data
public class AgendaItemRequest {
    private Long meetingId;
    private Long sectionId;
    private AgendaItemType itemType;
    private String title;
    private String numberLabel;
    private Integer displayOrder;
    private String description;
    private String mediaPath;
}
