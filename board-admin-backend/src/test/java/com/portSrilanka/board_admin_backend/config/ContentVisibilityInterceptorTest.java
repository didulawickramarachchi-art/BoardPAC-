package com.portSrilanka.board_admin_backend.config;

import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
import java.time.Instant;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ContentVisibilityInterceptorTest {
    private final ContentVisibilityService visibility = mock(ContentVisibilityService.class);
    private final ContentVisibilityInterceptor interceptor = new ContentVisibilityInterceptor(visibility);

    @AfterEach
    void clearSecurity() { SecurityContextHolder.clearContext(); }

    @Test
    void blocksContentForNonAdminsOnlyDuringPeriod() throws Exception {
        when(visibility.current()).thenReturn(new ContentVisibilityService.Period(Instant.EPOCH, Instant.MAX, true));
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "member", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_MEMBER"))));
        for (String path : java.util.List.of("/api/meetings", "/api/papers/3", "/api/files/content/token", "/api/dashboard/summary/1")) {
            MockHttpServletResponse response = new MockHttpServletResponse();
            assertFalse(interceptor.preHandle(new MockHttpServletRequest("GET", path), response, new Object()));
            assertEquals(403, response.getStatus());
        }
        assertTrue(interceptor.preHandle(new MockHttpServletRequest("GET", "/api/users/me"), new MockHttpServletResponse(), new Object()));
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "admin", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
        assertTrue(interceptor.preHandle(new MockHttpServletRequest("GET", "/api/papers"), new MockHttpServletResponse(), new Object()));
    }
}
