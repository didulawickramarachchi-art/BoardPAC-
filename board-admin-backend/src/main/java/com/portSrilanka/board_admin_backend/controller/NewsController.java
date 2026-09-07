package com.portSrilanka.board_admin_backend.controller;
import com.portSrilanka.board_admin_backend.dto.news.*;
import com.portSrilanka.board_admin_backend.service.NewsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/news") @RequiredArgsConstructor
public class NewsController {
    private final NewsService service;
    @GetMapping @PreAuthorize("isAuthenticated()") public ResponseEntity<List<NewsResponse>> all(Authentication a){return ResponseEntity.ok(service.getAll(a.getName()));}
    @PostMapping @PreAuthorize("hasRole('SECRETARY')") public ResponseEntity<NewsResponse> create(@RequestBody NewsRequest r,Authentication a){return ResponseEntity.ok(service.create(r,a.getName()));}
    @PutMapping("/{id}") @PreAuthorize("hasRole('SECRETARY')") public ResponseEntity<NewsResponse> update(@PathVariable Long id,@RequestBody NewsRequest r,Authentication a){return ResponseEntity.ok(service.update(id,r,a.getName()));}
    @DeleteMapping("/{id}") @PreAuthorize("hasRole('SECRETARY')") public ResponseEntity<Void> delete(@PathVariable Long id){service.delete(id);return ResponseEntity.noContent().build();}
    @PutMapping("/order") @PreAuthorize("hasRole('SECRETARY')") public ResponseEntity<Void> order(@RequestBody NewsRequest r){service.reorder(r);return ResponseEntity.noContent().build();}
    @PostMapping("/{id}/comments") @PreAuthorize("isAuthenticated()") public ResponseEntity<NewsResponse> comment(@PathVariable Long id,@RequestBody NewsRequest r,Authentication a){return ResponseEntity.ok(service.comment(id,r,a.getName()));}
    @PostMapping("/{id}/reactions") @PreAuthorize("isAuthenticated()") public ResponseEntity<NewsResponse> react(@PathVariable Long id,@RequestBody NewsRequest r,Authentication a){return ResponseEntity.ok(service.react(id,r,a.getName()));}
}
