package com.portSrilanka.board_admin_backend.dto.report;

import com.portSrilanka.board_admin_backend.enums.LoginStatus;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LoginHistoryResponse {
    private Long id;
    private String username;
    private String ipAddress;
    private String deviceInfo;
    private LoginStatus status;
    private LocalDateTime loginTime;
}
