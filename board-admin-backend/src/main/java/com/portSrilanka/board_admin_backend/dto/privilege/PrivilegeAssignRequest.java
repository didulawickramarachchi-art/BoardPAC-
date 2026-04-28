package com.portSrilanka.board_admin_backend.dto.privilege;

import lombok.Data;

@Data
public class PrivilegeAssignRequest {
    private Long userId;
    private Long subcategoryId;
    private String assignedRole;
    private Integer displaySequence;
}