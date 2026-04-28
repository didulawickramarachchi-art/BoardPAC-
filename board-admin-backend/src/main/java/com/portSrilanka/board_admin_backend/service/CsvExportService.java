package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AuditLog;
import com.portSrilanka.board_admin_backend.entity.LoginHistory;
import com.portSrilanka.board_admin_backend.repository.AuditLogRepository;
import com.portSrilanka.board_admin_backend.repository.LoginHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CsvExportService {

    private final LoginHistoryRepository loginHistoryRepository;
    private final AuditLogRepository auditLogRepository;

    public String exportLoginHistoryCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append("Id,Username,IP Address,Device,Status,Login Time\n");

        for (LoginHistory log : loginHistoryRepository.findAll()) {
            sb.append(log.getId()).append(",")
                    .append(safe(log.getUsername())).append(",")
                    .append(safe(log.getIpAddress())).append(",")
                    .append(safe(log.getDeviceInfo())).append(",")
                    .append(log.getStatus()).append(",")
                    .append(log.getLoginTime()).append("\n");
        }

        return sb.toString();
    }

    public String exportAuditLogsCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append("Id,Level,Module,Action,Username,Parameters,Device,Action Time\n");

        for (AuditLog log : auditLogRepository.findAll()) {
            sb.append(log.getId()).append(",")
                    .append(log.getLevel()).append(",")
                    .append(safe(log.getModuleName())).append(",")
                    .append(safe(log.getActionName())).append(",")
                    .append(safe(log.getUsername())).append(",")
                    .append(safe(log.getParameters())).append(",")
                    .append(safe(log.getDevice())).append(",")
                    .append(log.getActionTime()).append("\n");
        }

        return sb.toString();
    }

    private String safe(String value) {
        if (value == null) return "";
        return "\"" + value.replace("\"", "\"\"") + "\"";
        }
}
