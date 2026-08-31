package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class PaperReadStateResponse {
    private Long paperId;
    private boolean seen;
    private LocalDateTime firstOpenedAt;
    private LocalDateTime lastOpenedAt;
    private Integer lastPage;
    private Integer totalPages;
    private boolean completed;
}
