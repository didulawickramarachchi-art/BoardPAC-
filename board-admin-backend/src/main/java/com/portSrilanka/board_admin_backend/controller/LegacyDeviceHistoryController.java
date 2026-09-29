package com.portSrilanka.board_admin_backend.controller;

import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Old device inventory for review; it never approves a device in the new system. */
@RestController
@RequestMapping("/api/legacy-archive/devices")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class LegacyDeviceHistoryController {
    private final JdbcTemplate jdbc;

    @GetMapping
    public List<Map<String, Object>> list() {
        return jdbc.queryForList("SELECT source_id,device_identifier,mac_address,status_code,"
                + "description,device_info,version,os_name,device_type_code,last_version_updated_at "
                + "FROM legacy_device_inventory ORDER BY source_id");
    }
}
