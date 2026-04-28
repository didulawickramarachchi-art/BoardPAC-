package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.auth.RefreshTokenRequest;
import com.portSrilanka.board_admin_backend.dto.auth.RefreshTokenResponse;
import com.portSrilanka.board_admin_backend.service.RefreshTokenService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tokens")
@RequiredArgsConstructor
public class TokenController {

    private final RefreshTokenService refreshTokenService;

    @PostMapping("/refresh")
    public ResponseEntity<RefreshTokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(refreshTokenService.refresh(request.getRefreshToken()));
    }
}
