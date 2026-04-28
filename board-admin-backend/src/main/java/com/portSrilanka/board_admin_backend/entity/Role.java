package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.SystemRole;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role extends BaseEntity {

    @Enumerated(EnumType.STRING)
    @Column(unique = true, nullable = false)
    private SystemRole name;
}
