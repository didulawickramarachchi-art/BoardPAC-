package com.portSrilanka.board_admin_backend.dto.report;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LicenseUtilizationResponse {
    private long totalUsers;
    private long activeUsers;
    private long deactivatedUsers;
    private long lockedUsers;
    private long deletedUsers;
}
