package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.setting.WorkflowSettingCheckResponse;
import com.portSrilanka.board_admin_backend.service.WorkflowSettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/workflow-settings")
@RequiredArgsConstructor
public class WorkflowSettingController {

    private final WorkflowSettingService workflowSettingService;

    @GetMapping("/enabled")
    public ResponseEntity<WorkflowSettingCheckResponse> isEnabled(@RequestParam String key) {
        boolean enabled = workflowSettingService.isEnabled(key, false);
        String value = workflowSettingService.getValue(key, "false");

        return ResponseEntity.ok(
                WorkflowSettingCheckResponse.builder()
                        .enabled(enabled)
                        .settingKey(key)
                        .settingValue(value)
                        .build()
        );
    }
}