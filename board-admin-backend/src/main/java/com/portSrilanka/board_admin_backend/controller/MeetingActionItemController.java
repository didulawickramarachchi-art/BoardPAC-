package com.portSrilanka.board_admin_backend.controller;
import com.portSrilanka.board_admin_backend.dto.meeting.*;
import com.portSrilanka.board_admin_backend.service.MeetingActionItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity; import org.springframework.security.core.Authentication; import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/meetings/{meetingId}/action-items") @RequiredArgsConstructor
public class MeetingActionItemController {
 private final MeetingActionItemService service;
 @GetMapping public ResponseEntity<List<ActionItemResponse>> list(@PathVariable Long meetingId,Authentication a){return ResponseEntity.ok(service.list(meetingId,a.getName(),manager(a)));}
 @PostMapping public ResponseEntity<ActionItemResponse> create(@PathVariable Long meetingId,@RequestBody ActionItemRequest r,Authentication a){return ResponseEntity.ok(service.create(meetingId,r,a.getName(),manager(a)));}
 @PutMapping("/{id}/status") public ResponseEntity<ActionItemResponse> status(@PathVariable Long meetingId,@PathVariable Long id,@RequestBody ActionItemStatusRequest r,Authentication a){return ResponseEntity.ok(service.status(id,r,a.getName(),manager(a)));}
 @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable Long meetingId,@PathVariable Long id,Authentication a){service.delete(id,a.getName(),manager(a));return ResponseEntity.noContent().build();}
 private boolean manager(Authentication a){return a.getAuthorities().stream().anyMatch(x->x.getAuthority().equals("ROLE_SECRETARY")||x.getAuthority().equals("ROLE_ADMIN"));}
}
