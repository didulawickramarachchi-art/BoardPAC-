package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.AccessProfile;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service("accessProfileService")
@RequiredArgsConstructor
public class AccessProfileService {
    private final UserRepository userRepository;

    public boolean canComment(String username) {
        return switch (profile(username)) {
            case BOARD_SECRETARY, SECRETARY_ASSISTANT, MEMBER, MEMBER_VIEW_COMMENTS -> true;
            default -> false;
        };
    }

    public boolean canApprove(String username) {
        return switch (profile(username)) {
            case BOARD_SECRETARY, MEMBER -> true;
            default -> false;
        };
    }

    public boolean canAnnotate(String username) {
        return switch (profile(username)) {
            case BOARD_SECRETARY, MEMBER -> true;
            default -> false;
        };
    }

    public boolean canUploadPapers(String username) {
        return switch (profile(username)) {
            case BOARD_SECRETARY, SECRETARY_ASSISTANT, SECRETARY_UPLOAD_ONLY -> true;
            default -> false;
        };
    }

    public boolean canManageMeetings(String username) {
        return switch (profile(username)) {
            case BOARD_SECRETARY, SECRETARY_ASSISTANT -> true;
            default -> false;
        };
    }

    private AccessProfile profile(String username) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) return AccessProfile.MEMBER_VIEW_ONLY;
        if (user.getAccessProfile() != null) return user.getAccessProfile();
        SystemRole role = user.getRoles().stream()
                .map(item -> item.getName())
                .findFirst()
                .orElse(SystemRole.MEMBER);
        return AccessProfile.defaultFor(role);
    }
}
