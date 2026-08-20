package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Device;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import com.portSrilanka.board_admin_backend.repository.DeviceRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DeviceServiceTest {

    private DeviceRepository deviceRepository;
    private EmailService emailService;
    private NotificationService notificationService;
    private DeviceService deviceService;

    @BeforeEach
    void setUp() {
        deviceRepository = mock(DeviceRepository.class);
        emailService = mock(EmailService.class);
        notificationService = mock(NotificationService.class);
        deviceService = new DeviceService(
                deviceRepository,
                mock(UserRepository.class),
                emailService,
                notificationService
        );
    }

    @Test
    void approveShouldEmailTheUserWhoRequestedTheDevice() {
        User user = User.builder()
                .firstName("Nimal")
                .boardEmail("nimal@example.com")
                .build();
        Device device = Device.builder()
                .deviceId("device-123")
                .deviceInfo("Nimal's iPad")
                .status(DeviceStatus.PENDING)
                .user(user)
                .build();
        when(deviceRepository.findById(10L)).thenReturn(Optional.of(device));

        String result = deviceService.approve(10L);

        assertEquals("Device approved successfully", result);
        assertEquals(DeviceStatus.APPROVED, device.getStatus());
        verify(deviceRepository).save(device);
        verify(notificationService).notifyAdminsOfDeviceApproval(device);
        verify(emailService).sendEmail(
                eq("nimal@example.com"),
                eq("Device request approved"),
                contains("Nimal's iPad")
        );
    }

    @Test
    void approveShouldRemainSafeForAnUnassignedDevice() {
        Device device = Device.builder()
                .deviceId("legacy-device")
                .status(DeviceStatus.PENDING)
                .build();
        when(deviceRepository.findById(11L)).thenReturn(Optional.of(device));

        deviceService.approve(11L);

        assertEquals(DeviceStatus.APPROVED, device.getStatus());
        verify(emailService, never()).sendEmail(
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString()
        );
    }
}
