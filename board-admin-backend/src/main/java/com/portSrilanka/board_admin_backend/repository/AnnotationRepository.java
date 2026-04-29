package com.portSrilanka.board_admin_backend.repository;

import com.portSrilanka.board_admin_backend.entity.Annotation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AnnotationRepository extends JpaRepository<Annotation, Long> {
    List<Annotation> findByPaperIdAndUserId(Long paperId, Long userId);
    List<Annotation> findByUserId(Long userId);
}
