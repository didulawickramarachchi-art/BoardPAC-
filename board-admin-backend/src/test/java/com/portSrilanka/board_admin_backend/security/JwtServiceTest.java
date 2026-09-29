package com.portSrilanka.board_admin_backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {
    @Test
    void rejectsTokenAfterUserIsDisabled() {
        JwtService service = new JwtService();
        ReflectionTestUtils.setField(service, "secret", "test-signing-key-with-at-least-thirty-two-bytes");
        ReflectionTestUtils.setField(service, "expiration", 60000L);
        var active = User.withUsername("alice").password("hash").authorities("ROLE_MEMBER").build();
        String token = service.generateToken(active);
        assertTrue(service.isTokenValid(token, active));
        var disabled = User.withUsername("alice").password("hash").authorities("ROLE_MEMBER").disabled(true).build();
        assertFalse(service.isTokenValid(token, disabled));
    }
}
