package com.portSrilanka.board_admin_backend.dto.auth;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private String refreshToken;
    private String username;
    private String message;
    private boolean requiresTwoFactor;
}