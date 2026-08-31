package com.portSrilanka.board_admin_backend.controller;
import com.portSrilanka.board_admin_backend.dto.report.AuditLogResponse;
import com.portSrilanka.board_admin_backend.service.PersonalActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/activity") @RequiredArgsConstructor
public class PersonalActivityController {
 private final PersonalActivityService service;
 @GetMapping("/me") public ResponseEntity<List<AuditLogResponse>> mine(Authentication authentication){return ResponseEntity.ok(service.forUser(authentication.getName()));}
}
