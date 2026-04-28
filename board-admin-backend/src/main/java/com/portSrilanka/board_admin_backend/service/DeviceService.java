package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.device.*;
import com.portSrilanka.board_admin_backend.entity.Device;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.DeviceRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final UserRepository userRepository;

    public DeviceResponse create(DeviceRequest request) {
        if (deviceRepository.existsByDeviceId(request.getDeviceId())) {
            throw new BadRequestException("Device already exists");
        }

        User user = null;
        if (request.getUserId() != null) {
            user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        }

        Device device = Device.builder()
                .deviceId(request.getDeviceId())
                .deviceInfo(request.getDeviceInfo())
                .boardPacVersion(request.getBoardPacVersion())
                .osVersion(request.getOsVersion())
                .description(request.getDescription())
                .status(DeviceStatus.PENDING)
                .user(user)
                .build();

        return mapToResponse(deviceRepository.save(device));
    }

    public List<DeviceResponse> getAll() {
        return deviceRepository.findAll().stream().map(this::mapToResponse).toList();
    }

    public String approve(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.APPROVED);
        deviceRepository.save(device);
        return "Device approved successfully";
    }

    public String deactivate(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.DEACTIVATED);
        deviceRepository.save(device);
        return "Device deactivated successfully";
    }

    public String wipe(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.WIPED);
        deviceRepository.save(device);
        return "Device wiped successfully";
    }

    private Device findDevice(Long id) {
        return deviceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Device not found"));
    }

    private DeviceResponse mapToResponse(Device device) {
        return DeviceResponse.builder()
                .id(device.getId())
                .deviceId(device.getDeviceId())
                .deviceInfo(device.getDeviceInfo())
                .boardPacVersion(device.getBoardPacVersion())
                .osVersion(device.getOsVersion())
                .description(device.getDescription())
                .status(device.getStatus())
                .username(device.getUser() != null ? device.getUser().getUsername() : null)
                .build();
    }
}
