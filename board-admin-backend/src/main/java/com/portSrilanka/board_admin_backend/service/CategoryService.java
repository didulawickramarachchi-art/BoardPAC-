package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.category.*;
import com.portSrilanka.board_admin_backend.entity.Category;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryResponse create(CategoryRequest request) {
        if (categoryRepository.existsByName(request.getName())) {
            throw new BadRequestException("Category already exists");
        }

        Category category = Category.builder()
                .name(request.getName())
                .displayName(request.getDisplayName())
                .displayOrder(request.getDisplayOrder())
                .build();

        return map(categoryRepository.save(category));
    }

    public List<CategoryResponse> getAll() {
        return categoryRepository.findAll().stream().map(this::map).toList();
    }

    public CategoryResponse update(Long id, CategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        category.setName(request.getName());
        category.setDisplayName(request.getDisplayName());
        category.setDisplayOrder(request.getDisplayOrder());

        return map(categoryRepository.save(category));
    }

    @Transactional
    public String delete(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        categoryRepository.delete(category);
        return "Category and all related data deleted successfully";
    }

    private CategoryResponse map(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .displayName(category.getDisplayName())
                .displayOrder(category.getDisplayOrder())
                .build();
    }
}
