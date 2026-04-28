package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CommentResponse {
    private Long id;
    private String createdByUsername;
    private String commentText;
    private boolean annotated;
}
