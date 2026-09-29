package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.Subcategory;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LegacyPaperFileAccessServiceTest {
    private final PaperRepository papers = mock(PaperRepository.class);
    private final UserRepository users = mock(UserRepository.class);
    private final PermissionService permissions = mock(PermissionService.class);
    private final LegacyPaperFileAccessService access = new LegacyPaperFileAccessService(papers, users, permissions);

    @Test
    void servesImportedPaperOnlyWithAnActiveUserAndMatchingGrant() {
        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString("legacy-papers/7_9.pdf".getBytes(StandardCharsets.UTF_8));
        User user = new User(); user.setId(3L); user.setStatus(UserStatus.ACTIVE);
        Subcategory subcategory = new Subcategory(); subcategory.setId(2L);
        Meeting meeting = new Meeting(); meeting.setSubcategory(subcategory);
        Paper paper = new Paper(); paper.setMeeting(meeting);
        paper.setFilePath("http://localhost:8081/api/files/content/" + token);
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(papers.findById(7L)).thenReturn(Optional.of(paper));
        var auth = new UsernamePasswordAuthenticationToken("alice", null, List.of());

        assertThrows(AccessDeniedException.class, () -> access.authorize(token, auth));
        when(permissions.hasSubcategoryAccess(3L, 2L)).thenReturn(true);
        assertDoesNotThrow(() -> access.authorize(token, auth));

        user.setStatus(UserStatus.DEACTIVATED);
        assertThrows(AccessDeniedException.class, () -> access.authorize(token, auth));
    }

    @Test
    void deniesAFileWhoseTokenDoesNotMatchTheImportedPaper() {
        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString("legacy-papers/7_9.pdf".getBytes(StandardCharsets.UTF_8));
        User user = new User(); user.setId(3L); user.setStatus(UserStatus.ACTIVE);
        Paper paper = new Paper(); paper.setFilePath("http://localhost:8081/api/files/content/other");
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(papers.findById(7L)).thenReturn(Optional.of(paper));
        var auth = new UsernamePasswordAuthenticationToken("alice", null, List.of());
        assertThrows(AccessDeniedException.class, () -> access.authorize(token, auth));
    }
}
