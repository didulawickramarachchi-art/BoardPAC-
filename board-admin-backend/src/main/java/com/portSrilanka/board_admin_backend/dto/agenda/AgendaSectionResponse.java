package com.portSrilanka.board_admin_backend.dto.agenda;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AgendaSectionResponse {
    private Long id;
    private String title;
    private String numberLabel;
    private Integer displayOrder;
}
