package com.portSrilanka.board_admin_backend.dto.setting;

import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import lombok.Builder;
import lombok.Data;

@Data
public class SettingRequest {
    private SettingGroup settingGroup;
    private String settingKey;
    private String settingValue;
    private String description;
}