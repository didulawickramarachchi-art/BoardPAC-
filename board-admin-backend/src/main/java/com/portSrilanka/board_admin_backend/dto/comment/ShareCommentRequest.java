package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Data;

@Data
public class ShareCommentRequest {
    private Long commentId;
    private Long sharedByUserId;
    private Long sharedToUserId;
}
