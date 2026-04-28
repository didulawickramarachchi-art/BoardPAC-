package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.report.PackDeliveryResponse;
import com.portSrilanka.board_admin_backend.service.PackDeliveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pack-delivery")
@RequiredArgsConstructor
public class PackDeliveryController {

    private final PackDeliveryService packDeliveryService;

    @GetMapping("/paper/{paperId}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('BOARD_ADMIN') or hasRole('BOARD_SECRETARY')")
    public ResponseEntity<List<PackDeliveryResponse>> getByPaper(@PathVariable Long paperId) {
        return ResponseEntity.ok(packDeliveryService.getByPaper(paperId));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<PackDeliveryResponse>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(packDeliveryService.getByUser(userId));
    }
}
