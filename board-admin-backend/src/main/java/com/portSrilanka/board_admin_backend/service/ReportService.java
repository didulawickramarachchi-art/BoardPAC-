package com.portSrilanka.board_admin_backend.service;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.portSrilanka.board_admin_backend.dto.common.PageResponse;
import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.repository.AuditLogRepository;
import com.portSrilanka.board_admin_backend.repository.LoginHistoryRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.data.domain.PageRequest;
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
    public PageResponse<LoginHistoryResponse> getLoginHistoryPaged(int page, int size, String username) {
    Pageable pageable = PageRequest.of(page, size);
    Page<com.portSrilanka.board_admin_backend.entity.LoginHistory> result =
            (username != null && !username.isBlank())
                    ? loginHistoryRepository.findByUsernameContainingIgnoreCase(username, pageable)
                    : loginHistoryRepository.findAll(pageable);

    return PageResponse.<LoginHistoryResponse>builder()
            .content(result.getContent().stream()
                    .map(log -> LoginHistoryResponse.builder()
                            .id(log.getId())
                            .username(log.getUsername())
                            .ipAddress(log.getIpAddress())
                            .deviceInfo(log.getDeviceInfo())
                            .status(log.getStatus())
                            .loginTime(log.getLoginTime())
                            .build())
                    .toList())
            .page(result.getNumber())
            .size(result.getSize())
            .totalElements(result.getTotalElements())
            .totalPages(result.getTotalPages())
            .last(result.isLast())
            .build();
}

public PageResponse<AuditLogResponse> getAuditLogsPaged(int page, int size, String username) {
    Pageable pageable = PageRequest.of(page, size);
    Page<com.portSrilanka.board_admin_backend.entity.AuditLog> result =
            (username != null && !username.isBlank())
                    ? auditLogRepository.findByUsernameContainingIgnoreCase(username, pageable)
                    : auditLogRepository.findAll(pageable);

    return PageResponse.<AuditLogResponse>builder()
            .content(result.getContent().stream()
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
                    .toList())
            .page(result.getNumber())
            .size(result.getSize())
            .totalElements(result.getTotalElements())
            .totalPages(result.getTotalPages())
            .last(result.isLast())
            .build();
}
}