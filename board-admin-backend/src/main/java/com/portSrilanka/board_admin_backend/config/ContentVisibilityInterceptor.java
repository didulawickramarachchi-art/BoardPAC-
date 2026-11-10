package com.portSrilanka.board_admin_backend.config;

import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.PaperAttachmentRepository;
import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class ContentVisibilityInterceptor implements HandlerInterceptor {
    private final ContentVisibilityService visibility;
    private final PaperRepository papers;
    private final PaperAttachmentRepository attachments;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()))) return true;

        String path = request.getRequestURI().substring(request.getContextPath().length());
        boolean hidden = hiddenPath(path, request.getMethod());
        if (!hidden && "/api/files/upload".equals(path)) {
            hidden = visibility.isHiddenMeeting(number(request.getParameter("meetingId")))
                    || visibility.isHiddenPaper(number(request.getParameter("paperId")));
        }
        if (!hidden) return true;
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json");
        response.getWriter().write("{\"message\":\"This meeting and its papers are hidden by the administrator.\"}");
        return false;
    }

    boolean hiddenPath(String path, String method) {
        String[] part = path.split("/");
        if (part.length < 4 || !"api".equals(part[1])) return false;
        return switch (part[2]) {
            case "meetings" -> visibility.isHiddenMeeting(number(part[3]));
            case "meeting-workspace" -> visibility.isHiddenMeeting(number(part[3]));
            case "agendas" -> part.length > 4 && ("GET".equals(method) || "PUT".equals(method))
                    && visibility.isHiddenMeeting(number(part[4]));
            case "papers" -> {
                if ("meeting".equals(part[3]) && part.length > 4) yield visibility.isHiddenMeeting(number(part[4]));
                yield visibility.isHiddenPaper(number(part[3]));
            }
            case "attachments" -> "paper".equals(part[3]) && part.length > 4
                    && visibility.isHiddenPaper(number(part[4]));
            case "approvals", "annotations" -> "paper".equals(part[3]) && part.length > 4
                    && visibility.isHiddenPaper(number(part[4]));
            case "comments" -> part.length > 4 && ("paper".equals(part[3])
                    ? visibility.isHiddenPaper(number(part[4]))
                    : "meeting".equals(part[3]) && visibility.isHiddenMeeting(number(part[4])));
            case "paper-read-states" -> visibility.isHiddenPaper(number(part[3]));
            case "pack-delivery" -> "paper".equals(part[3]) && part.length > 4
                    && visibility.isHiddenPaper(number(part[4]));
            case "secure-files" -> "papers".equals(part[3]) && part.length > 4
                    && visibility.isHiddenPaper(number(part[4]));
            case "files" -> {
                if (!"content".equals(part[3]) || part.length <= 4) yield false;
                String suffix = "/api/files/content/" + part[4];
                yield papers.findByFilePathEndingWith(suffix).stream().anyMatch(visibility::isHidden)
                        || attachments.findByFilePathEndingWith(suffix).stream()
                            .anyMatch(attachment -> visibility.isHidden(attachment.getPaper()));
            }
            default -> false;
        };
    }

    private Long number(String value) {
        if (value == null) return null;
        try { return Long.valueOf(value); }
        catch (NumberFormatException ex) { return null; }
    }
}
