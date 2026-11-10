package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.AccessProfile;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AccessProfileServiceTest {
    @Test
    void onlyBoardSecretaryCanManageMeetings() {
        UserRepository users = mock(UserRepository.class);
        AccessProfileService access = new AccessProfileService(users);
        User user = new User();
        when(users.findByUsername("secretary")).thenReturn(Optional.of(user));

        user.setAccessProfile(AccessProfile.SECRETARY_ASSISTANT);
        assertFalse(access.canManageMeetings("secretary"));
        assertTrue(access.canUploadPapers("secretary"));

        user.setAccessProfile(AccessProfile.SECRETARY_UPLOAD_ONLY);
        assertFalse(access.canManageMeetings("secretary"));

        user.setAccessProfile(AccessProfile.BOARD_SECRETARY);
        assertTrue(access.canManageMeetings("secretary"));
    }
}
