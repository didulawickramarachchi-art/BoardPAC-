package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.repository.AuditLogRepository;
import com.portSrilanka.board_admin_backend.repository.LoginHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final LoginHistoryRepository loginHistoryRepository;
    private final AuditLogRepository auditLogRepository;

    public List<LoginHistoryResponse> getLoginHistory() {
        return loginHistoryRepository.findAll().stream()
                .map(log -> LoginHistoryResponse.builder()
                        .id(log.getId())
                        .username(log.getUsername())
                        .ipAddress(log.getIpAddress())
                        .deviceInfo(log.getDeviceInfo())
                        .status(log.getStatus())
                        .loginTime(log.getLoginTime())
                        .build())
                .toList();
    }

    public List<AuditLogResponse> getAuditLogs() {
        return auditLogRepository.findAll().stream()
                .map(log -> AuditLogResponse.builder()
                        .id(log.getId())
                        .level(log.getLevel())
                        .moduleName(log.getModuleName())
                        .actionName(log.getActionName())
                        .username(log.getUsername())
                        .parameters(log.getParameters())
                        .device(log.getDevice())
                        .actionTime(log.getActionTime())
                        .build())
                .toList();
    }
}
