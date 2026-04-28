package com.portSrilanka.board_admin_backend.entity;

import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "app_settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppSetting extends BaseEntity {

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SettingGroup settingGroup;

    @Column(nullable = false, unique = true)
    private String settingKey;

    @Column(nullable = false, length = 2000)
    private String settingValue;

    private String description;
}
