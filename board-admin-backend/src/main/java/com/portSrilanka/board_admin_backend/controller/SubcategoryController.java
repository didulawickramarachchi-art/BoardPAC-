package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.subcategory.*;
import com.portSrilanka.board_admin_backend.service.SubcategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/subcategories")
@RequiredArgsConstructor
public class SubcategoryController {

    private final SubcategoryService subcategoryService;

    @PostMapping
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<SubcategoryResponse> create(@RequestBody SubcategoryRequest request) {
        return ResponseEntity.ok(subcategoryService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SECRETARY') or hasRole('MEMBER')")
    public ResponseEntity<List<SubcategoryResponse>> getAll() {
        return ResponseEntity.ok(subcategoryService.getAll());
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<SubcategoryResponse> update(@PathVariable Long id, @RequestBody SubcategoryRequest request) {
        return ResponseEntity.ok(subcategoryService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SECRETARY')")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        return ResponseEntity.ok(subcategoryService.delete(id));
    }
}
