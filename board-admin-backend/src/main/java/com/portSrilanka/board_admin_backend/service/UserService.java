package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.user.*;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.dto.common.PageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public UserResponse getUserById(Long id) {
        return mapToResponse(findUser(id));
    }

    public UserResponse updateUser(Long id, UserRequest request) {
        User user = findUser(id);

        user.setSalutation(request.getSalutation());
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setDisplayName(request.getDisplayName());
        user.setBoardEmail(request.getBoardEmail());
        user.setOfficeEmail(request.getOfficeEmail());
        user.setOfficeNumber(request.getOfficeNumber());
        user.setMobileNumber(request.getMobileNumber());
        user.setJobTitle(request.getJobTitle());
        user.setProfilePictureUrl(request.getProfilePictureUrl());
        user.setBoardType(request.getBoardType());
        user.setTwoStepEnabled(request.isTwoStepEnabled());

        userRepository.save(user);

        return mapToResponse(user);
    }

    public String deactivateUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.DEACTIVATED);
        userRepository.save(user);

        auditService.logInfo("USER", "DEACTIVATE_USER", user.getUsername(),
                "User deactivated", "WEB");

        return "User deactivated successfully";
    }

    public String activateUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);

        auditService.logInfo("USER", "ACTIVATE_USER", user.getUsername(),
                "User activated", "WEB");

        return "User activated successfully";
    }

    public String deleteUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.DELETED);
        userRepository.save(user);

        auditService.logInfo("USER", "DELETE_USER", user.getUsername(),
                "User marked deleted", "WEB");

        return "User deleted successfully";
    }

    public String resetPassword(Long id) {
        User user = findUser(id);

        String temporaryPassword = "Temp@12345";
        user.setPassword(passwordEncoder.encode(temporaryPassword));
        userRepository.save(user);

        auditService.logInfo("USER", "RESET_PASSWORD", user.getUsername(),
                "Temporary password reset", "WEB");

        return "Password reset successfully. Temporary password: " + temporaryPassword;
    }

    public String lockUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.LOCKED);
        userRepository.save(user);

        auditService.logInfo("USER", "LOCK_USER", user.getUsername(),
                "User locked", "WEB");

        return "User locked successfully";
    }

    public String unlockUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);

        auditService.logInfo("USER", "UNLOCK_USER", user.getUsername(),
                "User unlocked", "WEB");

        return "User unlocked successfully";
    }

    private User findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));
    }

    private UserResponse mapToResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .displayName(user.getDisplayName())
                .boardEmail(user.getBoardEmail())
                .mobileNumber(user.getMobileNumber())
                .jobTitle(user.getJobTitle())
                .boardType(user.getBoardType())
                .status(user.getStatus())
                .build();
    }
    public PageResponse<UserResponse> getUsersPaged(int page, int size, String search, UserStatus status) {
    Pageable pageable = PageRequest.of(page, size);
    Page<User> result;

    if (search != null && !search.isBlank()) {
        result = userRepository.findByUsernameContainingIgnoreCase(search, pageable);
    } else if (status != null) {
        result = userRepository.findByStatus(status, pageable);
    } else {
        result = userRepository.findAll(pageable);
    }

    return PageResponse.<UserResponse>builder()
            .content(result.getContent().stream().map(this::mapToResponse).toList())
            .page(result.getNumber())
            .size(result.getSize())
            .totalElements(result.getTotalElements())
            .totalPages(result.getTotalPages())
            .last(result.isLast())
            .build();
}
}
