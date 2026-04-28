package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.setting.*;
import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.AppSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SettingService {

    private final AppSettingRepository appSettingRepository;
    private final AuditService auditService;

    public SettingResponse createOrUpdate(SettingRequest request) {
        AppSetting setting = appSettingRepository.findBySettingKey(request.getSettingKey())
                .orElse(
                        AppSetting.builder()
                                .settingKey(request.getSettingKey())
                                .build()
                );

        setting.setSettingGroup(request.getSettingGroup());
        setting.setSettingValue(request.getSettingValue());
        setting.setDescription(request.getDescription());

        setting = appSettingRepository.save(setting);

        auditService.logInfo("SETTING", "UPSERT_SETTING", "SYSTEM",
                request.getSettingKey() + "=" + request.getSettingValue(), "WEB");

        return map(setting);
    }

    public List<SettingResponse> getAll() {
        return appSettingRepository.findAll().stream().map(this::map).toList();
    }

    public List<SettingResponse> getByGroup(SettingGroup group) {
        return appSettingRepository.findBySettingGroup(group).stream().map(this::map).toList();
    }

    public SettingResponse getByKey(String key) {
        AppSetting setting = appSettingRepository.findBySettingKey(key)
                .orElseThrow(() -> new ResourceNotFoundException("Setting not found"));
        return map(setting);
    }

    private SettingResponse map(AppSetting setting) {
        return SettingResponse.builder()
                .id(setting.getId())
                .settingGroup(setting.getSettingGroup())
                .settingKey(setting.getSettingKey())
                .settingValue(setting.getSettingValue())
                .description(setting.getDescription())
                .build();
    }
}