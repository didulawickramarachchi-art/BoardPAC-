package com.portSrilanka.board_admin_backend.dto.agenda;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SharedAgendaItemResponse {
    private Long id;
    private Long sourceAgendaItemId;
    private String sourceAgendaItemTitle;
    private Long sourceSubcategoryId;
    private String sourceSubcategoryName;
    private Long targetSubcategoryId;
    private String targetSubcategoryName;
    private String sharedByUsername;
    private boolean active;
}