package com.portSrilanka.board_admin_backend.dto.report;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserCategoryReportResponse {
    private Long userId;
    private String username;
    private String categoryName;
    private String subcategoryName;
    private String assignedRole;
}