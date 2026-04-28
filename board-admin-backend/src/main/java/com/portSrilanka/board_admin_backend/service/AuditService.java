package com.portSrilanka.board_admin_backend.service;


import com.portSrilanka.board_admin_backend.entity.AuditLog;
import com.portSrilanka.board_admin_backend.enums.AuditLevel;
import com.portSrilanka.board_admin_backend.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public void logInfo(String module, String action, String username, String parameters, String device) {
        auditLogRepository.save(
                AuditLog.builder()
                        .level(AuditLevel.INFO)
                        .moduleName(module)
                        .actionName(action)
                        .username(username)
                        .parameters(parameters)
                        .device(device)
                        .actionTime(LocalDateTime.now())
                        .build()
        );
    }

    public void logError(String module, String action, String username, String parameters, String device) {
        auditLogRepository.save(
                AuditLog.builder()
                        .level(AuditLevel.ERROR)
                        .moduleName(module)
                        .actionName(action)
                        .username(username)
                        .parameters(parameters)
                        .device(device)
                        .actionTime(LocalDateTime.now())
                        .build()
        );
    }
}