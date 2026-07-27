package com.portSrilanka.board_admin_backend.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PasswordResetEmailRequest {
    @NotBlank
    @Email
    private String email;
}
