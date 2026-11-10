package com.portSrilanka.board_admin_backend.config;

import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.PaperAttachmentRepository;
import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
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
    private final ContentVisibilityInterceptor interceptor = new ContentVisibilityInterceptor(visibility, mock(PaperRepository.class), mock(PaperAttachmentRepository.class));

    @AfterEach
    void clearSecurity() { SecurityContextHolder.clearContext(); }

    @Test
    void blocksOnlyHiddenRecordsAndKeepsListsAvailable() throws Exception {
        when(visibility.isHiddenMeeting(3L)).thenReturn(true);
        when(visibility.isHiddenPaper(7L)).thenReturn(true);
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "member", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_MEMBER"))));
        for (String path : java.util.List.of("/api/meetings/3/participants", "/api/papers/7", "/api/secure-files/papers/7")) {
            MockHttpServletResponse response = new MockHttpServletResponse();
            assertFalse(interceptor.preHandle(new MockHttpServletRequest("GET", path), response, new Object()));
            assertEquals(403, response.getStatus());
        }
        for (String path : java.util.List.of("/api/meetings", "/api/papers", "/api/meetings/4/participants", "/api/dashboard/summary/1")) {
            assertTrue(interceptor.preHandle(new MockHttpServletRequest("GET", path), new MockHttpServletResponse(), new Object()));
        }
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "admin", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
        assertTrue(interceptor.preHandle(new MockHttpServletRequest("GET", "/api/papers/7"), new MockHttpServletResponse(), new Object()));
    }
}
