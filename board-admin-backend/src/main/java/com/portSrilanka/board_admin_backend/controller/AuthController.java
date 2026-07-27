package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.auth.*;
import com.portSrilanka.board_admin_backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final com.portSrilanka.board_admin_backend.service.PasswordResetService passwordResetService;

    @PostMapping(value = "/register", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping(value = "/login", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<LoginResponse> loginJson(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping(value = "/password-reset/request", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> requestPasswordReset(
            @Valid @RequestBody PasswordResetEmailRequest request
    ) {
        passwordResetService.sendResetEmail(request.getEmail());
        return ResponseEntity.ok("If the email is registered, a password-change link has been sent");
    }

    @PostMapping(value = "/reset-password", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> resetPassword(
            @Valid @RequestBody PasswordResetRequest request
    ) {
        passwordResetService.resetPassword(request);
        return ResponseEntity.ok("Password changed successfully");
    }

    @PostMapping(value = "/login", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public ResponseEntity<LoginResponse> loginForm(@Valid @ModelAttribute LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping(value = "/verify-2fa", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<LoginResponse> verifyTwoFactor(@Valid @RequestBody TwoFactorVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyTwoFactor(request.getUsername(), request.getCode()));
    }
}
