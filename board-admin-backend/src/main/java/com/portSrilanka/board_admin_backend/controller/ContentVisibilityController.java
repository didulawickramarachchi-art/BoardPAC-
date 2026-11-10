package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/content-visibility")
@RequiredArgsConstructor
public class ContentVisibilityController {
    private final ContentVisibilityService visibility;

    public record ScheduleRequest(LocalDate startDate, LocalDate endDate) {}

    @GetMapping
    public ContentVisibilityService.Period current() {
        return visibility.current();
    }

    @PutMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> schedule(@RequestBody ScheduleRequest request) {
        if (request == null || request.startDate() == null || request.endDate() == null
                || request.startDate().isAfter(request.endDate())) {
            return ResponseEntity.badRequest().body("Start date must be on or before end date");
        }
        return ResponseEntity.ok(visibility.schedule(request.startDate(), request.endDate()));
    }

    @DeleteMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> clear() {
        visibility.clear();
        return ResponseEntity.noContent().build();
    }
}
