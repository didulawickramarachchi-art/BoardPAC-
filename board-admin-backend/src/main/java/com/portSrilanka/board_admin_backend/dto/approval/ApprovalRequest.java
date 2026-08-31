package com.portSrilanka.board_admin_backend.dto.approval;

import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import lombok.Data;

@Data
public class ApprovalRequest {
    private Long paperId;
    private ApprovalStatus approvalStatus;
    private String approvalComment;
}
