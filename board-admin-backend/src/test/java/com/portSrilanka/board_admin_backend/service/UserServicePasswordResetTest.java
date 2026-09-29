package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.repository.RoleRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class UserServicePasswordResetTest {
    @Test
    void generatesDifferentTemporaryPasswordsForSeparateResets() {
        UserRepository users = mock(UserRepository.class);
        PasswordEncoder encoder = mock(PasswordEncoder.class);
        User user = new User(); user.setId(7L); user.setUsername("legacy-user");
        when(users.findById(7L)).thenReturn(Optional.of(user));
        when(encoder.encode(anyString())).thenAnswer(call -> call.getArgument(0));
        UserService service = new UserService(users, mock(RoleRepository.class), encoder,
                mock(AuditService.class), mock(FileStorageService.class));

        String first = service.resetPassword(7L);
        String second = service.resetPassword(7L);
        assertNotEquals(first, second);
        assertFalse(first.contains("Temp@12345"));
        assertTrue(first.substring(first.lastIndexOf(' ') + 1).length() >= 32);
    }
}
