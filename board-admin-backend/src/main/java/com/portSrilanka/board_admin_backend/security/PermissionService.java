package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.entity.UserSubcategoryAccess;
import com.portSrilanka.board_admin_backend.repository.UserSubcategoryAccessRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PermissionService {

    private final UserSubcategoryAccessRepository accessRepository;

    public boolean hasSubcategoryAccess(Long userId, Long subcategoryId) {
        return accessRepository.findByUserId(userId).stream()
                .anyMatch(a -> a.getSubcategory().getId().equals(subcategoryId));
    }

    public boolean hasRoleInSubcategory(Long userId, Long subcategoryId, String roleName) {
        return accessRepository.findByUserId(userId).stream()
                .anyMatch(a ->
                        a.getSubcategory().getId().equals(subcategoryId)
                                && a.getAssignedRole() != null
                                && a.getAssignedRole().equalsIgnoreCase(roleName)
                );
    }
}
