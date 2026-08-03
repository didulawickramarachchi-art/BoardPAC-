package com.portSrilanka.board_admin_backend.dto.notification;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NotificationRequest {
    private String title;
    private String message;
    private String type;
    private Long createdByUserId;
    private Long targetUserId;
    private Long relatedMeetingId;
    private Long relatedPaperId;
    private Long relatedCommentId;
    private Long relatedAttachmentId;
    private boolean announcement;
}
