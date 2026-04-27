package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceRepository extends JpaRepository<Device, Long> {
    boolean existsByDeviceId(String deviceId);
}