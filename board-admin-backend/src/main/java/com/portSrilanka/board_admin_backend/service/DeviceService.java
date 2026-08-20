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
    private final EmailService emailService;
    private final NotificationService notificationService;

    public DeviceResponse create(DeviceRequest request) {
        User user = null;
        if (request.getUserId() != null) {
            user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        }

        if (user != null && deviceRepository.existsByDeviceIdAndUserId(
                request.getDeviceId(), user.getId())) {
            throw new BadRequestException("Device request already exists for this user");
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

        Device savedDevice = deviceRepository.save(device);
        notificationService.notifyAdminsOfPendingDevice(savedDevice);
        return mapToResponse(savedDevice);
    }

    public List<DeviceResponse> getAll() {
        return deviceRepository.findAll().stream().map(this::mapToResponse).toList();
    }

    public String approve(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.APPROVED);
        deviceRepository.save(device);
        notificationService.notifyAdminsOfDeviceApproval(device);

        User user = device.getUser();
        if (user != null && user.getBoardEmail() != null && !user.getBoardEmail().isBlank()) {
            String deviceName = device.getDeviceInfo() == null || device.getDeviceInfo().isBlank()
                    ? device.getDeviceId()
                    : device.getDeviceInfo();
            emailService.sendEmail(
                    user.getBoardEmail(),
                    "Device request approved",
                    "Hello " + user.getFirstName() + ",\n\n"
                            + "Your request for device " + deviceName + " has been approved."
                            + " You can now use this device to access BoardPAC.\n\n"
                            + "Regards,\nBoardPAC Team"
            );
        }
        return "Device approved successfully";
    }

    public String deactivate(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.DEACTIVATED);
        deviceRepository.save(device);
        return "Device deactivated successfully";
    }

    public String activate(Long id) {
        Device device = findDevice(id);
        if (device.getStatus() != DeviceStatus.DEACTIVATED) {
            throw new BadRequestException("Only deactivated devices can be activated");
        }
        device.setStatus(DeviceStatus.APPROVED);
        deviceRepository.save(device);
        return "Device activated successfully";
    }

    public String wipe(Long id) {
        Device device = findDevice(id);
        device.setStatus(DeviceStatus.WIPED);
        deviceRepository.save(device);
        return "Device wiped successfully";
    }

    public void delete(Long id) {
        Device device = findDevice(id);
        if (device.getStatus() != DeviceStatus.WIPED) {
            throw new BadRequestException("Only wiped devices can be deleted");
        }
        deviceRepository.delete(device);
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
