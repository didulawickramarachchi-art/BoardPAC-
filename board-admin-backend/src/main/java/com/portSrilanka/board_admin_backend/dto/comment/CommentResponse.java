package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
public class CommentResponse {
    private Long id;
    private String createdByUsername;
    private String commentText;
    private boolean annotated;
    private LocalDateTime createdAt;
    private long reactionCount;
    private boolean reactedByCurrentUser;
    private String currentReaction;
    private Map<String, Long> reactionCounts;
}
