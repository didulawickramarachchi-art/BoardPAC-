package com.portSrilanka.board_admin_backend.dto.comment;

import lombok.Data;

@Data
public class CommentRequest {
    private Long meetingId;
    private Long paperId;
    private String commentText;
    private boolean annotated;
    private String visibility;
    private Integer pageNumber;
    private java.util.Set<Long> selectedUserIds;
}
