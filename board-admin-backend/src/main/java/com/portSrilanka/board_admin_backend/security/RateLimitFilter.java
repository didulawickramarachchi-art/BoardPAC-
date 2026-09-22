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
    private static final int LIMIT = 200;
    private static final long WINDOW_MILLIS = 60_000L;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        long now = System.currentTimeMillis();
        String client = clientAddress(request);
        RequestWindow window = requestCounts.compute(client, (key, current) -> {
            if (current == null || now - current.startedAt >= WINDOW_MILLIS) {
                return new RequestWindow(now, 1);
            }
            current.count++;
            return current;
        });

        if (window.count > LIMIT) {
            response.setStatus(429);
            response.setContentType("application/json");
            long retryAfterSeconds = Math.max(1, (WINDOW_MILLIS - (now - window.startedAt) + 999) / 1000);
            response.setHeader("Retry-After", Long.toString(retryAfterSeconds));
            response.getWriter().write("{\"message\":\"Too many requests. Please retry shortly.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String clientAddress(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",", 2)[0].trim();
        }
        return request.getRemoteAddr();
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
