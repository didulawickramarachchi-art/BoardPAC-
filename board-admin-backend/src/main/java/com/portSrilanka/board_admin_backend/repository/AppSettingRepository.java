package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.AppSetting;
import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AppSettingRepository extends JpaRepository<AppSetting, Long> {
    Optional<AppSetting> findBySettingKey(String settingKey);
    List<AppSetting> findBySettingGroup(SettingGroup settingGroup);
}