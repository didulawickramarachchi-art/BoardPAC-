package com.portSrilanka.board_admin_backend.dto.approval;

import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ApprovalResponse {
    private Long id;
    private Long userId;
    private String username;
    private ApprovalStatus approvalStatus;
    private String approvalComment;
    private java.time.LocalDateTime createdAt;
    private java.time.LocalDateTime updatedAt;
    private boolean ownedByCurrentUser;
}
