package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.auth.PasswordResetRequest;
import com.portSrilanka.board_admin_backend.entity.PasswordResetToken;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.PasswordResetTokenRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;

@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final AuditService auditService;
    private final RefreshTokenService refreshTokenService;
    private final SessionService sessionService;

    @Value("${app.password-reset.frontend-url:http://localhost:8080/#/reset-password}")
    private String frontendUrl;

    @Value("${app.password-reset.expiration-minutes:30}")
    private long expirationMinutes;

    @Transactional
    public void sendResetEmail(String email) {
        // Return the same response for existing and missing accounts to prevent
        // attackers from discovering registered email addresses.
        userRepository.findByBoardEmailIgnoreCase(email.trim()).ifPresent(this::createAndSendToken);
    }

    private void createAndSendToken(User user) {
        tokenRepository.deleteByUser(user);

        byte[] randomBytes = new byte[32];
        SECURE_RANDOM.nextBytes(randomBytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);

        PasswordResetToken token = new PasswordResetToken();
        token.setUser(user);
        token.setTokenHash(hash(rawToken));
        token.setExpiresAt(LocalDateTime.now().plusMinutes(expirationMinutes));
        tokenRepository.save(token);

        String separator = frontendUrl.contains("?") ? "&" : "?";
        String resetLink = frontendUrl + separator + "token=" + rawToken;
        emailService.sendEmail(
                user.getBoardEmail(),
                "Change your BoardPAC password",
                "A password change was requested for your BoardPAC account.\n\n"
                        + "Use this secure link to choose a new password:\n"
                        + resetLink + "\n\n"
                        + "This link expires in " + expirationMinutes + " minutes and can be used once. "
                        + "If you did not request this change, you can ignore this email."
        );
    }

    @Transactional
    public void resetPassword(PasswordResetRequest request) {
        PasswordResetToken token = tokenRepository.findByTokenHash(hash(request.getToken()))
                .orElseThrow(() -> new BadRequestException("Invalid or expired password reset link"));

        LocalDateTime now = LocalDateTime.now();
        if (token.getUsedAt() != null || token.getExpiresAt().isBefore(now)) {
            throw new BadRequestException("Invalid or expired password reset link");
        }

        User user = token.getUser();
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        refreshTokenService.revokeAllUserTokens(user.getId());
        sessionService.revokeAllUserSessions(user.getId());
        token.setUsedAt(now);
        tokenRepository.save(token);

        auditService.logInfo(
                "USER",
                "CHANGE_PASSWORD",
                user.getUsername(),
                "Password changed using email reset link",
                "WEB"
        );
    }

    private String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
