package com.portSrilanka.board_admin_backend.config;

import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class ContentVisibilityInterceptor implements HandlerInterceptor {
    private static final Set<String> CONTENT_ROOTS = Set.of(
            "meetings", "meeting-workspace", "papers", "paper-read-states", "agendas",
            "attachments", "annotations", "comments", "approvals", "favorites",
            "pack-delivery", "secure-files", "local-files", "meeting-history-report", "dashboard",
            "reports", "admin-reports", "notifications", "activity"
    );
    private final ContentVisibilityService visibility;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws IOException {
        String path = request.getRequestURI().substring(request.getContextPath().length());
        if (!isContentPath(path) && !(path.equals("/api/files/upload")
                && (request.getParameter("meetingId") != null || request.getParameter("paperId") != null))) return true;
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return true;
        if (auth.getAuthorities().stream().anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()))) return true;
        if (!visibility.current().active()) return true;
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json");
        response.getWriter().write("{\"message\":\"Meetings and papers are temporarily hidden by the administrator.\"}");
        return false;
    }

    static boolean isContentPath(String path) {
        if (path.equals("/api/files/content") || path.startsWith("/api/files/content/")) return true;
        if (path.equals("/api/files/download") || path.startsWith("/api/files/download/")) return true;
        if (!path.startsWith("/api/")) return false;
        String rest = path.substring(5);
        int separator = rest.indexOf('/');
        return CONTENT_ROOTS.contains(separator < 0 ? rest : rest.substring(0, separator));
    }
}
