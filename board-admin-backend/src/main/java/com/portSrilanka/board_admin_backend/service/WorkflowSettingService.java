package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class WorkflowSettingService {

    private final AppSettingRepository appSettingRepository;

    public boolean isEnabled(String key, boolean defaultValue) {
        return appSettingRepository.findBySettingKey(key)
                .map(setting -> Boolean.parseBoolean(setting.getSettingValue()))
                .orElse(defaultValue);
    }

    public String getValue(String key, String defaultValue) {
        return appSettingRepository.findBySettingKey(key)
                .map(AppSetting::getSettingValue)
                .orElse(defaultValue);
    }

    public void requireEnabled(String key, String message) {
        if (!isEnabled(key, false)) {
            throw new BadRequestException(message);
        }
    }

    public void validatePastMeetingCreation(java.time.LocalDateTime meetingDateTime) {
        boolean allowed = isEnabled("ENABLE_CREATE_MEETINGS_WITH_PAST_DATES", false);
        if (!allowed && meetingDateTime.isBefore(java.time.LocalDateTime.now())) {
            throw new BadRequestException("Creating meetings with past dates is disabled");
        }
    }

    public void validateReferenceNumber(String referenceNumber) {
        boolean mandatory = isEnabled("MANDATORY_PAPER_REFERENCE_NUMBER", false);
        if (mandatory && (referenceNumber == null || referenceNumber.isBlank())) {
            throw new BadRequestException("Paper reference number is mandatory");
        }
    }

    public void validateApprovalComment(String approvalComment) {
        boolean enabled = isEnabled("ENABLE_APPROVAL_COMMENTS_FOR_BOARD_MEMBER", true);
        if (!enabled && approvalComment != null && !approvalComment.isBlank()) {
            throw new BadRequestException("Approval comments are disabled");
        }
    }
}