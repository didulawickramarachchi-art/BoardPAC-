package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.FileAccessLog;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.FileAccessLogRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class SecureFileAccessService {

    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final FileAccessLogRepository fileAccessLogRepository;
    private final PermissionService permissionService;

    public String getAuthorizedPaperPath(Long paperId, Long userId, String action, String channel) {
        Paper paper = paperRepository.findById(paperId)
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        boolean allowed = permissionService.hasSubcategoryAccess(userId, paper.getMeeting().getSubcategory().getId());
        if (!allowed) {
            throw new ResourceNotFoundException("Access denied for this paper");
        }

        fileAccessLogRepository.save(
                FileAccessLog.builder()
                        .paper(paper)
                        .user(user)
                        .actionName(action)
                        .fileName(paper.getFileName())
                        .actionTime(LocalDateTime.now())
                        .channel(channel)
                        .build()
        );

        return paper.getFilePath();
    }
}
