package com.portSrilanka.board_admin_backend.dto.agenda;

import lombok.Data;
import java.util.List;

@Data
public class AgendaOrderRequest {
    private List<Long> orderedIds;
}
