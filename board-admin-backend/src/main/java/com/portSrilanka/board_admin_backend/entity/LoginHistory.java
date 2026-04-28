package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.LoginStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "login_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginHistory extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    private String username;
    private String ipAddress;
    private String deviceInfo;

    @Enumerated(EnumType.STRING)
    private LoginStatus status;

    private LocalDateTime loginTime;
}