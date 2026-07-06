package com.portSrilanka.board_admin_backend.dto.access;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AccessValidationResponse {
    private Long userId;
    private String username;
    private String requestedChannel;
    private boolean allowed;
    private String reason;
}
