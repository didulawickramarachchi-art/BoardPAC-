package com.portSrilanka.board_admin_backend.dto.device;

import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DeviceResponse {
    private Long id;
    private String deviceId;
    private String deviceInfo;
    private String boardPacVersion;
    private String osVersion;
    private String description;
    private DeviceStatus status;
    private String username;
}