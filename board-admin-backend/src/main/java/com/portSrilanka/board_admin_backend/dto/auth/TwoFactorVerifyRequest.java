package com.portSrilanka.board_admin_backend.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TwoFactorVerifyRequest {
    @NotBlank
    private String username;

    @NotBlank
    private String code;
}