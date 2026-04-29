package com.portSrilanka.board_admin_backend.dto.setting;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class WorkflowSettingCheckResponse {
    private boolean enabled;
    private String settingKey;
    private String settingValue;
}