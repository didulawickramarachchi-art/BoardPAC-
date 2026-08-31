package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.List;

@Data
@Builder
public class CommentResponse {
    private Long id;
    private Long createdByUserId;
    private String createdByUsername;
    private String createdByProfilePictureUrl;
    private String commentText;
    private boolean annotated;
    private String visibility;
    private Integer pageNumber;
    private boolean ownedByCurrentUser;
    private List<Long> selectedUserIds;
    private LocalDateTime updatedAt;
    private LocalDateTime createdAt;
    private long reactionCount;
    private boolean reactedByCurrentUser;
    private String currentReaction;
    private Map<String, Long> reactionCounts;
    private List<Reply> replies;

    @Data
    @Builder
    public static class Reply {
        private Long id;
        private Long createdByUserId;
        private String createdByUsername;
        private String createdByProfilePictureUrl;
        private String message;
        private LocalDateTime createdAt;
    }
}
