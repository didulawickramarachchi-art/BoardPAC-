package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Data;

@Data
public class PaperReadStateRequest {
    private Integer lastPage;
    private Integer totalPages;
}
