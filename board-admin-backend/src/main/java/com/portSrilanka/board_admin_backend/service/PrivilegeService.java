package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.privilege.*;
import com.portSrilanka.board_admin_backend.entity.Subcategory;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.entity.UserSubcategoryAccess;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.SubcategoryRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.repository.UserSubcategoryAccessRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PrivilegeService {

    private final UserSubcategoryAccessRepository accessRepository;
    private final UserRepository userRepository;
    private final SubcategoryRepository subcategoryRepository;
    private final AuditService auditService;

    public PrivilegeResponse assign(PrivilegeAssignRequest request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Subcategory subcategory = subcategoryRepository.findById(request.getSubcategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Subcategory not found"));

        UserSubcategoryAccess access = UserSubcategoryAccess.builder()
                .user(user)
                .subcategory(subcategory)
                .assignedRole(request.getAssignedRole())
                .displaySequence(request.getDisplaySequence())
                .build();

        access = accessRepository.save(access);

        auditService.logInfo("PRIVILEGE", "ASSIGN_PRIVILEGE", user.getUsername(),
                "Assigned to subcategory " + subcategory.getName(), "WEB");

        return map(access);
    }

    public List<PrivilegeResponse> getAll() {
        return accessRepository.findAll().stream().map(this::map).toList();
    }

    public List<PrivilegeResponse> getByUser(Long userId) {
        return accessRepository.findByUserId(userId).stream().map(this::map).toList();
    }

    public String remove(Long userId, Long subcategoryId) {
        accessRepository.deleteByUserIdAndSubcategoryId(userId, subcategoryId);
        auditService.logInfo("PRIVILEGE", "REMOVE_PRIVILEGE",
                "SYSTEM", "Removed privilege for userId=" + userId + ", subcategoryId=" + subcategoryId, "WEB");
        return "Privilege removed successfully";
    }

    private PrivilegeResponse map(UserSubcategoryAccess access) {
        return PrivilegeResponse.builder()
                .id(access.getId())
                .userId(access.getUser().getId())
                .username(access.getUser().getUsername())
                .subcategoryId(access.getSubcategory().getId())
                .subcategoryName(access.getSubcategory().getName())
                .assignedRole(access.getAssignedRole())
                .displaySequence(access.getDisplaySequence())
                .build();
    }
}
