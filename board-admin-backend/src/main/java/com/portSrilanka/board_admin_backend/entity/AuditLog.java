package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.AuditLevel    ;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "audit_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog extends BaseEntity {

    @Enumerated(EnumType.STRING)
    private AuditLevel level;

    private String moduleName;
    private String actionName;
    private String username;

    @Column(length = 2000)
    private String parameters;

    private String device;

    private LocalDateTime actionTime;
}