package com.portSrilanka.board_admin_backend.dto.agenda;

import lombok.Data;

@Data
public class ShareAgendaItemRequest {
    private Long agendaItemId;
    private Long targetSubcategoryId;
    private Long sharedByUserId;
}