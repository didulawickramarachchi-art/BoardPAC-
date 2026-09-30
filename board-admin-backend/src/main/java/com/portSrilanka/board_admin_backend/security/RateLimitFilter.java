package com.portSrilanka.board_admin_backend.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final ConcurrentHashMap<String, RequestWindow> requestCounts = new ConcurrentHashMap<>();
    private static final int LOGIN_LIMIT = 30;
    private static final int PASSWORD_RESET_LIMIT = 10;
    private static final long WINDOW_MILLIS = 60_000L;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        int limit = limitFor(request);
        if (limit == 0) {
            filterChain.doFilter(request, response);
            return;
        }

        long now = System.currentTimeMillis();
        String client = clientAddress(request) + ":" + request.getRequestURI();
        RequestWindow window = requestCounts.compute(client, (key, current) -> {
            if (current == null || now - current.startedAt >= WINDOW_MILLIS) {
                return new RequestWindow(now, 1);
            }
            current.count++;
            return current;
        });

        if (window.count > limit) {
            response.setStatus(429);
            response.setContentType("application/json");
            long retryAfterSeconds = Math.max(1, (WINDOW_MILLIS - (now - window.startedAt) + 999) / 1000);
            response.setHeader("Retry-After", Long.toString(retryAfterSeconds));
            response.getWriter().write("{\"message\":\"Too many requests. Please retry shortly.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private int limitFor(HttpServletRequest request) {
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return 0;
        }
        return switch (request.getRequestURI()) {
            case "/api/auth/login", "/api/auth/verify-2fa" -> LOGIN_LIMIT;
            case "/api/auth/password-reset/request", "/api/auth/reset-password" -> PASSWORD_RESET_LIMIT;
            default -> 0;
        };
    }

    private String clientAddress(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        String remote = request.getRemoteAddr();
        // Only the local reverse proxy may supply the client's address.
        if (("10.105.4.183".equals(remote) || "127.0.0.1".equals(remote)
                || "::1".equals(remote)) && forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",", 2)[0].trim();
        }
        return remote;
    }

    private static final class RequestWindow {
        private final long startedAt;
        private int count;

        private RequestWindow(long startedAt, int count) {
            this.startedAt = startedAt;
            this.count = count;
        }
    }
}
