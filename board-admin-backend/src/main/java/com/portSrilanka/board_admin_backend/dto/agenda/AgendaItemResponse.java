package com.portSrilanka.board_admin_backend.dto.agenda;

import com.portSrilanka.board_admin_backend.enums.AgendaItemType;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AgendaItemResponse {
    private Long id;
    private Long sectionId;
    private AgendaItemType itemType;
    private String title;
    private String numberLabel;
    private Integer displayOrder;
    private String description;
}
