package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.user.*;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream().map(this::mapToResponse).toList();
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

        return mapToResponse(userRepository.save(user));
    }

    public String deactivateUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.DEACTIVATED);
        userRepository.save(user);
        return "User deactivated successfully";
    }

    public String activateUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);
        return "User activated successfully";
    }

    public String deleteUser(Long id) {
        User user = findUser(id);
        user.setStatus(UserStatus.DELETED);
        userRepository.save(user);
        return "User deleted successfully";
    }

    private User findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
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
}