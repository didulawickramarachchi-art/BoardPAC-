package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.device.*;
import com.portSrilanka.board_admin_backend.service.DeviceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public class DeviceController {

    private final DeviceService deviceService;

    @PostMapping
    public ResponseEntity<DeviceResponse> create(@RequestBody DeviceRequest request) {
        return ResponseEntity.ok(deviceService.create(request));
    }

    @GetMapping
    public ResponseEntity<List<DeviceResponse>> getAll() {
        return ResponseEntity.ok(deviceService.getAll());
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<String> approve(@PathVariable Long id) {
        return ResponseEntity.ok(deviceService.approve(id));
    }

    @PutMapping("/{id}/deactivate")
    public ResponseEntity<String> deactivate(@PathVariable Long id) {
        return ResponseEntity.ok(deviceService.deactivate(id));
    }

    @PutMapping("/{id}/wipe")
    public ResponseEntity<String> wipe(@PathVariable Long id) {
        return ResponseEntity.ok(deviceService.wipe(id));
    }
}