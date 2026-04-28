package com.portSrilanka.board_admin_backend.dto.paper;

import lombok.Data;

@Data
public class SharePaperRequest {
    private Long paperId;
    private Long sharedByUserId;
    private Long sharedToUserId;
}
