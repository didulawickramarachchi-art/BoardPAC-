package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.AccessChannel;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSession extends BaseEntity {

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true, length = 500)
    private String sessionToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AccessChannel accessChannel;

    private String deviceInfo;
    private String ipAddress;
    private LocalDateTime expiresAt;
    private boolean active;
}
