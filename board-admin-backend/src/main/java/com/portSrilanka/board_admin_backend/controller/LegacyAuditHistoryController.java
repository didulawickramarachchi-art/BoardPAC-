package com.portSrilanka.board_admin_backend.controller;

import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Read-only admin view of old audit events, separate from the app's active logs. */
@RestController
@RequestMapping("/api/legacy-archive/audit-events")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class LegacyAuditHistoryController {
    private final JdbcTemplate jdbc;

    @GetMapping
    public List<Map<String, Object>> list(@RequestParam(defaultValue = "0") int page) {
        if (page < 0 || page > 100000) throw new IllegalArgumentException("Invalid page");
        return jdbc.queryForList("SELECT source_kind,source_id,event_time,module_name,action_name,"
                + "username,event_text,event_status,description FROM legacy_audit_events "
                + "ORDER BY event_time DESC NULLS LAST,source_kind,source_id DESC LIMIT 100 OFFSET ?", page * 100);
    }
}
