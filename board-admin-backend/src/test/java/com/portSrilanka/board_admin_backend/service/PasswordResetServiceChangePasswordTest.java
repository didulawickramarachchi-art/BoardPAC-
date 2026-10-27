package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.PasswordResetTokenRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class PasswordResetServiceChangePasswordTest {
    private final UserRepository users = mock(UserRepository.class);
    private final PasswordEncoder encoder = mock(PasswordEncoder.class);
    private final RefreshTokenService refreshTokens = mock(RefreshTokenService.class);
    private final SessionService sessions = mock(SessionService.class);
    private final AuditService audit = mock(AuditService.class);
    private final PasswordResetService service = new PasswordResetService(users,
            mock(PasswordResetTokenRepository.class), encoder, mock(EmailService.class),
            audit, refreshTokens, sessions);

    @Test
    void rejectsIncorrectCurrentPasswordWithoutChangingAccount() {
        User user = account();
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(encoder.matches("wrong", "old-hash")).thenReturn(false);

        assertThrows(BadRequestException.class,
                () -> service.changePassword("alice", "wrong", "NewPassword123"));
        assertEquals("old-hash", user.getPassword());
        verify(users, never()).save(any());
        verifyNoInteractions(refreshTokens, sessions);
    }

    @Test
    void changesPasswordAndRevokesExistingSessions() {
        User user = account();
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(encoder.matches("OldPassword123", "old-hash")).thenReturn(true);
        when(encoder.matches("NewPassword123", "old-hash")).thenReturn(false);
        when(encoder.encode("NewPassword123")).thenReturn("new-hash");

        service.changePassword("alice", "OldPassword123", "NewPassword123");

        assertEquals("new-hash", user.getPassword());
        verify(users).save(user);
        verify(refreshTokens).revokeAllUserTokens(7L);
        verify(sessions).revokeAllUserSessions(7L);
        verify(audit).logInfo("USER", "CHANGE_PASSWORD", "alice",
                "Password changed from profile", "WEB");
    }

    private User account() {
        User user = new User();
        user.setId(7L);
        user.setUsername("alice");
        user.setPassword("old-hash");
        return user;
    }
}
