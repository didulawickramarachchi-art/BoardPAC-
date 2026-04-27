package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "devices")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Device extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String deviceId;

    private String deviceInfo;
    private String boardPacVersion;
    private String osVersion;
    private String description;

    @Enumerated(EnumType.STRING)
    private DeviceStatus status;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}