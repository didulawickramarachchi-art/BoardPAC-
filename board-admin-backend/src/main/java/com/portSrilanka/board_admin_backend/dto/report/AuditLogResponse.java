package com.portSrilanka.board_admin_backend.dto.report;

import com.portSrilanka.board_admin_backend.enums.AuditLevel;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AuditLogResponse {
    private Long id;
    private AuditLevel level;
    private String moduleName;
    private String actionName;
    private String username;
    private String parameters;
    private String device;
    private LocalDateTime actionTime;
}