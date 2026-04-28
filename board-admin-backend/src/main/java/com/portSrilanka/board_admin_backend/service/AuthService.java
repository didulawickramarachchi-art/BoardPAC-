package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.auth.*;
import com.portSrilanka.board_admin_backend.entity.LoginHistory;
import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.LoginStatus;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.LoginHistoryRepository;
import com.portSrilanka.board_admin_backend.repository.RoleRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.*;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;



import java.util.Set;

@Service
@RequiredArgsConstructor
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

    public String register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username already exists");
        }

        if (userRepository.existsByBoardEmail(request.getBoardEmail())) {
            throw new BadRequestException("Board email already exists");
        }

        Role userRole = roleRepository.findByName(SystemRole.BOARD_ADMIN)
                .orElseThrow(() -> new BadRequestException("Default role not found"));

        User user = User.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .boardEmail(request.getBoardEmail())
                .boardType(request.getBoardType())
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

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new BadRequestException("Invalid credentials"));

        UserDetails userDetails = org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities(user.getRoles().stream()
                        .map(r -> "ROLE_" + r.getName().name())
                        .toArray(String[]::new))
                .build();

        String token = jwtService.generateToken(userDetails);

        loginHistoryRepository.save(
                LoginHistory.builder()
                        .user(user)
                        .username(user.getUsername())
                        .ipAddress("N/A")
                        .deviceInfo("WEB")
                        .status(LoginStatus.SUCCESS)
                        .loginTime(java.time.LocalDateTime.now())
                        .build()
        );

        return LoginResponse.builder()
                .token(token)
                .username(user.getUsername())
                .message("Login successful")
                .build();

    } catch (Exception ex) {
        loginHistoryRepository.save(
                LoginHistory.builder()
                        .username(request.getUsername())
                        .ipAddress("N/A")
                        .deviceInfo("WEB")
                        .status(LoginStatus.FAILED)
                        .loginTime(java.time.LocalDateTime.now())
                        .build()
        );
        throw ex;
    }
}
public LoginResponse verifyTwoFactor(String username, String code) {
    User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new BadRequestException("User not found"));

    twoFactorService.verifyCode(user, code);

    UserDetails userDetails = org.springframework.security.core.userdetails.User
            .withUsername(user.getUsername())
            .password(user.getPassword())
            .authorities(user.getRoles().stream()
                    .map(r -> "ROLE_" + r.getName().name())
                    .toArray(String[]::new))
            .build();

    String token = jwtService.generateToken(userDetails);
    String refreshToken = refreshTokenService.createRefreshToken(user);

    auditService.logInfo("AUTH", "VERIFY_2FA_SUCCESS", user.getUsername(),
            "2FA verified successfully", "WEB");

    return LoginResponse.builder()
            .token(token)
            .refreshToken(refreshToken)
            .username(user.getUsername())
            .message("2FA verification successful")
            .requiresTwoFactor(false)
            .build();
}
}
