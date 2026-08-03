package com.portSrilanka.board_admin_backend.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank
    private String username;

    @NotBlank
    private String password;

    @NotBlank
    private String deviceId;

    private String deviceInfo;
    private String boardPacVersion;
    private String osVersion;
    private String description;
}
