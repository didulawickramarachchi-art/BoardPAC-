package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.ContentVisibilityService;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/content-visibility")
@RequiredArgsConstructor
public class ContentVisibilityController {
    private final ContentVisibilityService visibility;

    public record ScheduleRequest(Instant startAt, Instant endAt) {}

    @GetMapping
    public ContentVisibilityService.Period current() {
        return visibility.current();
    }

    @PutMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> schedule(@RequestBody ScheduleRequest request) {
        if (request == null || request.startAt() == null || request.endAt() == null
                || !request.startAt().isBefore(request.endAt())) {
            return ResponseEntity.badRequest().body("Start time must be before end time");
        }
        return ResponseEntity.ok(visibility.schedule(request.startAt(), request.endAt()));
    }

    @DeleteMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> clear() {
        visibility.clear();
        return ResponseEntity.noContent().build();
    }
}
