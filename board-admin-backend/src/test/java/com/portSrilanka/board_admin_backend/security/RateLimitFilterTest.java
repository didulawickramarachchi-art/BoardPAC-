package com.portSrilanka.board_admin_backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RateLimitFilterTest {

    private final RateLimitFilter filter = new RateLimitFilter();

    @Test
    void ordinaryApiTrafficIsNotBlockedByTheLoginLimit() throws Exception {
        for (int i = 0; i < 250; i++) {
            MockHttpServletResponse response = request("GET", "/api/meetings", "192.0.2.21");
            assertEquals(200, response.getStatus());
        }
    }

    @Test
    void repeatedLoginRequestsAreLimited() throws Exception {
        for (int i = 0; i < 30; i++) {
            assertEquals(200, request("POST", "/api/auth/login", "192.0.2.22").getStatus());
        }
        MockHttpServletResponse response = request("POST", "/api/auth/login", "192.0.2.22");
        assertEquals(429, response.getStatus());
        assertNotNull(response.getHeader("Retry-After"));
    }

    private MockHttpServletResponse request(String method, String path, String address) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest(method, path);
        request.setRemoteAddr(address);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }
}
