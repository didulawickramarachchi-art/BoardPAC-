package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.auth.RefreshTokenResponse;
import com.portSrilanka.board_admin_backend.entity.RefreshToken;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.RefreshTokenRepository;
import com.portSrilanka.board_admin_backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;

    @Value("${app.jwt.refresh-expiration}")
    private long refreshExpirationMillis;

    public String createRefreshToken(User user) {
        RefreshToken refreshToken = RefreshToken.builder()
                .token(UUID.randomUUID().toString())
                .user(user)
                .expiresAt(LocalDateTime.now().plusSeconds(refreshExpirationMillis / 1000))
                .revoked(false)
                .build();

        return refreshTokenRepository.save(refreshToken).getToken();
    }

    public RefreshTokenResponse refresh(String token) {
        RefreshToken refreshToken = refreshTokenRepository.findByTokenAndRevokedFalse(token)
                .orElseThrow(() -> new BadRequestException("Invalid refresh token"));

        if (refreshToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Refresh token expired");
        }

        User user = refreshToken.getUser();

        UserDetails userDetails = org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities(user.getRoles().stream()
                        .map(r -> "ROLE_" + r.getName().authorityName())
                        .toArray(String[]::new))
                .build();

        String newAccessToken = jwtService.generateToken(userDetails);
        String newRefreshToken = createRefreshToken(user);

        refreshToken.setRevoked(true);
        refreshTokenRepository.save(refreshToken);

        return RefreshTokenResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .build();
    }

    public void revoke(String token) {
        refreshTokenRepository.findByTokenAndRevokedFalse(token).ifPresent(rt -> {
            rt.setRevoked(true);
            refreshTokenRepository.save(rt);
        });
    }

    public void revokeAllUserTokens(Long userId) {
        refreshTokenRepository.findByUserIdAndRevokedFalse(userId).forEach(token -> {
            token.setRevoked(true);
            refreshTokenRepository.save(token);
        });
    }
}
