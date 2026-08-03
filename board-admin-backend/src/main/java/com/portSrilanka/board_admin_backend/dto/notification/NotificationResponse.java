package com.portSrilanka.board_admin_backend.dto.notification;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Getter
@Builder
public class NotificationResponse {
    private Long id;
    private String title;
    private String message;
    private String type;
    private boolean read;
    private boolean announcement;
    private Long createdByUserId;
    private String createdByName;
    private String createdByProfilePictureUrl;
    private Long relatedMeetingId;
    private Long relatedPaperId;
    private Long relatedCommentId;
    private Long relatedAttachmentId;
    private List<Reply> replies;
    private Map<String, Long> reactionCounts;
    private String currentReaction;
    private LocalDateTime createdAt;

    @Getter
    @Builder
    public static class Reply {
        private Long id;
        private Long userId;
        private String userName;
        private String profilePictureUrl;
        private String message;
        private LocalDateTime createdAt;
    }
}
