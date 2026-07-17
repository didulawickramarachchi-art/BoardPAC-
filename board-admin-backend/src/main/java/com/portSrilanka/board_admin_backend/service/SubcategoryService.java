package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.subcategory.*;
import com.portSrilanka.board_admin_backend.entity.Category;
import com.portSrilanka.board_admin_backend.entity.Subcategory;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.CategoryRepository;
import com.portSrilanka.board_admin_backend.repository.SubcategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SubcategoryService {

    private final SubcategoryRepository subcategoryRepository;
    private final CategoryRepository categoryRepository;

    public SubcategoryResponse create(SubcategoryRequest request) {
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        Subcategory subcategory = Subcategory.builder()
                .name(request.getName())
                .displayName(request.getDisplayName())
                .displayOrder(request.getDisplayOrder())
                .category(category)
                .build();

        return map(subcategoryRepository.save(subcategory));
    }

    public List<SubcategoryResponse> getAll() {
        return subcategoryRepository.findAll().stream().map(this::map).toList();
    }

    public SubcategoryResponse update(Long id, SubcategoryRequest request) {
        Subcategory subcategory = subcategoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Subcategory not found"));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        subcategory.setName(request.getName());
        subcategory.setDisplayName(request.getDisplayName());
        subcategory.setDisplayOrder(request.getDisplayOrder());
        subcategory.setCategory(category);

        return map(subcategoryRepository.save(subcategory));
    }

    @Transactional
    public String delete(Long id) {
        Subcategory subcategory = subcategoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Subcategory not found"));
        subcategoryRepository.delete(subcategory);
        return "Subcategory and all related data deleted successfully";
    }

    private SubcategoryResponse map(Subcategory subcategory) {
        return SubcategoryResponse.builder()
                .id(subcategory.getId())
                .name(subcategory.getName())
                .displayName(subcategory.getDisplayName())
                .displayOrder(subcategory.getDisplayOrder())
                .categoryId(subcategory.getCategory().getId())
                .categoryName(subcategory.getCategory().getName())
                .build();
    }
}
