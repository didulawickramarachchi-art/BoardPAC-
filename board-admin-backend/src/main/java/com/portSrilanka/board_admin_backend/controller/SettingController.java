package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.setting.*;
import com.portSrilanka.board_admin_backend.enums.SettingGroup;
import com.portSrilanka.board_admin_backend.service.SettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN')")
public class SettingController {

    private final SettingService settingService;

    @PostMapping
    public ResponseEntity<SettingResponse> createOrUpdate(@RequestBody SettingRequest request) {
        return ResponseEntity.ok(settingService.createOrUpdate(request));
    }

    @GetMapping
    public ResponseEntity<List<SettingResponse>> getAll() {
        return ResponseEntity.ok(settingService.getAll());
    }

    @GetMapping("/group/{group}")
    public ResponseEntity<List<SettingResponse>> getByGroup(@PathVariable SettingGroup group) {
        return ResponseEntity.ok(settingService.getByGroup(group));
    }

    @GetMapping("/key/{key}")
    public ResponseEntity<SettingResponse> getByKey(@PathVariable String key) {
        return ResponseEntity.ok(settingService.getByKey(key));
    }
}