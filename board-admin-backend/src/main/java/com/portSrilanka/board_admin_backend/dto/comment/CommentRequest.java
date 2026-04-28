package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Data;

@Data
public class CommentRequest {
    private Long meetingId;
    private Long paperId;
    private Long createdByUserId;
    private String commentText;
    private boolean annotated;
}
