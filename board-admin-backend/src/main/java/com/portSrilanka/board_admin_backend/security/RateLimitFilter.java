package com.portSrilanka.board_admin_backend.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Map<String, Integer> requestCounts = new ConcurrentHashMap<>();
    private static final int LIMIT = 200;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String ip = request.getRemoteAddr();
        requestCounts.put(ip, requestCounts.getOrDefault(ip, 0) + 1);

        if (requestCounts.get(ip) > LIMIT) {
            response.setStatus(429);
            response.getWriter().write("Too many requests");
            return;
        }

        filterChain.doFilter(request, response);
    }
}
