package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.auth.*;
import com.portSrilanka.board_admin_backend.entity.LoginHistory;
import com.portSrilanka.board_admin_backend.entity.Device;
import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.LoginStatus;
import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.LoginHistoryRepository;
import com.portSrilanka.board_admin_backend.repository.DeviceRepository;
import com.portSrilanka.board_admin_backend.repository.RoleRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.*;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;



import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final LoginHistoryRepository loginHistoryRepository;
    private final TwoFactorService twoFactorService;
    private final RefreshTokenService refreshTokenService;
    private final AuditService auditService;
    private final DeviceRepository deviceRepository;

    public String register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username already exists");
        }

        if (userRepository.existsByBoardEmail(request.getBoardEmail())) {
            throw new BadRequestException("Board email already exists");
        }

        SystemRole requestedRole = request.getRole() != null
                ? request.getRole()
                : SystemRole.MEMBER;

        Role userRole = roleRepository.findByName(requestedRole)
                .orElseThrow(() -> new BadRequestException("Role not found: " + requestedRole));

        User user = User.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .boardEmail(request.getBoardEmail())
                .status(UserStatus.ACTIVE)
                .roles(Set.of(userRole))
                .build();

        userRepository.save(user);
        return "User registered successfully";
    }

    public LoginResponse login(LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getUsername(),
                            request.getPassword()
                    )
            );
        } catch (AuthenticationException ex) {
            recordLoginHistory(null, request.getUsername(), LoginStatus.FAILED);
            throw ex;
        }

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new BadRequestException("Invalid credentials"));

        requireApprovedDevice(request, user);

        if (user.isTwoStepEnabled()) {
            twoFactorService.generateAndSendCode(user);
            auditService.logInfo("AUTH", "2FA_CODE_SENT", user.getUsername(),
                    "Two-factor verification code sent", "WEB");

            return LoginResponse.builder()
                    .userId(user.getId())
                    .username(user.getUsername())
                    .role(getPrimaryRole(user))
                    .message("Verification code sent to your email")
                    .requiresTwoFactor(true)
                    .build();
        }

        UserDetails userDetails = org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities(user.getRoles().stream()
                        .map(r -> "ROLE_" + r.getName().authorityName())
                        .toArray(String[]::new))
                .build();

        String token = jwtService.generateToken(userDetails);

        recordLoginHistory(user, user.getUsername(), LoginStatus.SUCCESS);

        return LoginResponse.builder()
                .token(token)
                .userId(user.getId())
                .username(user.getUsername())
                .role(getPrimaryRole(user))
                .message("Login successful")
                .build();
    }

    private void requireApprovedDevice(LoginRequest request, User user) {
        Device device = deviceRepository.findByDeviceIdAndUserId(
                        request.getDeviceId(), user.getId())
                .orElseGet(() -> deviceRepository.save(Device.builder()
                        .deviceId(request.getDeviceId())
                        .deviceInfo(request.getDeviceInfo())
                        .boardPacVersion(request.getBoardPacVersion())
                        .osVersion(request.getOsVersion())
                        .description(request.getDescription())
                        .status(DeviceStatus.PENDING)
                        .user(user)
                        .build()));

        boolean firstDeviceBootstrap =
                !deviceRepository.existsByStatusAndUserRolesName(
                        DeviceStatus.APPROVED, SystemRole.ADMIN)
                        && isAdministrator(user);

        if (firstDeviceBootstrap) {
            device.setUser(user);
            device.setStatus(DeviceStatus.APPROVED);
            deviceRepository.save(device);
            auditService.logInfo("DEVICE", "BOOTSTRAP_APPROVAL", user.getUsername(),
                    "Claimed and approved the first administrator device",
                    device.getDeviceInfo());
            return;
        }

        if (device.getStatus() != DeviceStatus.APPROVED) {
            recordLoginHistory(user, user.getUsername(), LoginStatus.FAILED);
            if (device.getStatus() == DeviceStatus.PENDING) {
                throw new BadRequestException(
                        "This device is awaiting administrator approval. Your request has been sent.");
            }
            throw new BadRequestException(
                    "This device is not authorized. Contact an administrator.");
        }
    }

    private boolean isAdministrator(User user) {
        return user.getRoles().stream()
                .anyMatch(role -> SystemRole.ADMIN == role.getName());
    }

    private String getPrimaryRole(User user) {
        return user.getRoles().stream()
                .findFirst()
                .map(role -> role.getName().name())
                .orElse(SystemRole.MEMBER.name());
    }

    private void recordLoginHistory(User user, String username, LoginStatus status) {
        try {
            loginHistoryRepository.save(
                    LoginHistory.builder()
                            .user(user)
                            .username(username)
                            .ipAddress("N/A")
                            .deviceInfo("WEB")
                            .status(status)
                            .loginTime(java.time.LocalDateTime.now())
                            .build()
            );
        } catch (RuntimeException ex) {
            log.warn("Unable to record {} login history for user {}", status, username, ex);
        }
    }
public LoginResponse verifyTwoFactor(TwoFactorVerifyRequest request) {
    User user = userRepository.findByUsername(request.getUsername())
            .orElseThrow(() -> new BadRequestException("User not found"));

    requireApprovedDevice(toLoginRequest(request), user);
    twoFactorService.verifyCode(user, request.getCode());

    UserDetails userDetails = org.springframework.security.core.userdetails.User
            .withUsername(user.getUsername())
            .password(user.getPassword())
            .authorities(user.getRoles().stream()
                    .map(r -> "ROLE_" + r.getName().authorityName())
                    .toArray(String[]::new))
            .build();

    String token = jwtService.generateToken(userDetails);
    String refreshToken = refreshTokenService.createRefreshToken(user);

    auditService.logInfo("AUTH", "VERIFY_2FA_SUCCESS", user.getUsername(),
            "2FA verified successfully", "WEB");
    recordLoginHistory(user, user.getUsername(), LoginStatus.SUCCESS);

    return LoginResponse.builder()
            .token(token)
            .refreshToken(refreshToken)
            .userId(user.getId())
            .username(user.getUsername())
            .role(getPrimaryRole(user))
            .message("2FA verification successful")
            .requiresTwoFactor(false)
            .build();
}

private LoginRequest toLoginRequest(TwoFactorVerifyRequest request) {
    LoginRequest loginRequest = new LoginRequest();
    loginRequest.setUsername(request.getUsername());
    loginRequest.setDeviceId(request.getDeviceId());
    loginRequest.setDeviceInfo(request.getDeviceInfo());
    loginRequest.setBoardPacVersion(request.getBoardPacVersion());
    loginRequest.setOsVersion(request.getOsVersion());
    loginRequest.setDescription(request.getDescription());
    return loginRequest;
}
}
