package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Device;
import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DeviceRepository extends JpaRepository<Device, Long> {
    boolean existsByDeviceIdAndUserId(String deviceId, Long userId);
    Optional<Device> findByDeviceIdAndUserId(String deviceId, Long userId);
    long countByStatus(DeviceStatus status);
    boolean existsByStatusAndUserRolesName(DeviceStatus status, SystemRole role);
}
