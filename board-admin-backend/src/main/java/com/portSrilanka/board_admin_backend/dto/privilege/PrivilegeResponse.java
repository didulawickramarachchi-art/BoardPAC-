package com.portSrilanka.board_admin_backend.dto.privilege;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PrivilegeResponse {
    private Long id;
    private Long userId;
    private String username;
    private Long subcategoryId;
    private String subcategoryName;
    private String assignedRole;
    private Integer displaySequence;
}