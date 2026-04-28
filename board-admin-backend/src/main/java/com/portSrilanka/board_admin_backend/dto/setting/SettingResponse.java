package com.portSrilanka.board_admin_backend.dto.setting;

import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SettingResponse {
    private Long id;
    private SettingGroup settingGroup;
    private String settingKey;
    private String settingValue;
    private String description;
}
