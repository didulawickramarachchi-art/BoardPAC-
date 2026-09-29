package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

/** Applies the imported subcategory grants before serving a migrated board paper. */
@Service
@RequiredArgsConstructor
public class LegacyPaperFileAccessService {
    private static final Pattern LEGACY_PATH = Pattern.compile("legacy-papers/([0-9]+)_([0-9]+)\\.(pdf|pptx)");
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final PermissionService permissionService;

    public void authorize(String token, Authentication authentication) {
        String path;
        try { path = new String(Base64.getUrlDecoder().decode(token), StandardCharsets.UTF_8); }
        catch (IllegalArgumentException e) { throw new AccessDeniedException("Invalid file token"); }
        if (!path.startsWith("legacy-papers/")) return;
        Matcher match = LEGACY_PATH.matcher(path);
        if (!match.matches() || authentication == null || !authentication.isAuthenticated())
            throw new AccessDeniedException("Paper file access denied");
        long paperId;
        try { paperId = Long.parseLong(match.group(1)); }
        catch (NumberFormatException e) { throw new AccessDeniedException("Paper file access denied"); }
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new AccessDeniedException("Paper file access denied"));
        Paper paper = paperRepository.findById(paperId)
                .orElseThrow(() -> new AccessDeniedException("Paper file access denied"));
        if (user.getStatus() != UserStatus.ACTIVE || paper.getFilePath() == null
                || !paper.getFilePath().endsWith("/api/files/content/" + token)
                || paper.getMeeting() == null
                || !permissionService.hasSubcategoryAccess(user.getId(), paper.getMeeting().getSubcategory().getId()))
            throw new AccessDeniedException("Paper file access denied");
    }
}
