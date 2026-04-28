package com.portSrilanka.board_admin_backend.dto.device;

import lombok.Data;

@Data
public class DeviceRequest {
    private String deviceId;
    private String deviceInfo;
    private String boardPacVersion;
    private String osVersion;
    private String description;
    private Long userId;
}
