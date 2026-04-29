package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.annotation.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AnnotationService {

    private final AnnotationRepository annotationRepository;
    private final AnnotationBackupRepository annotationBackupRepository;
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AnnotationResponse create(AnnotationRequest request) {
        Paper paper = paperRepository.findById(request.getPaperId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Annotation annotation = Annotation.builder()
                .paper(paper)
                .user(user)
                .annotationType(request.getAnnotationType())
                .annotationDataJson(request.getAnnotationDataJson())
                .pageNumber(request.getPageNumber())
                .build();

        annotation = annotationRepository.save(annotation);

        auditService.logInfo("ANNOTATION", "CREATE_ANNOTATION",
                user.getUsername(), "Annotation added to paper " + paper.getTitle(), "DEVICE");

        return map(annotation);
    }

    public List<AnnotationResponse> getByPaperAndUser(Long paperId, Long userId) {
        return annotationRepository.findByPaperIdAndUserId(paperId, userId)
                .stream()
                .map(this::map)
                .toList();
    }

    public AnnotationBackupResponse backup(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        List<Annotation> annotations = annotationRepository.findByUserId(userId);

        try {
            String backupJson = objectMapper.writeValueAsString(
                    annotations.stream().map(a -> AnnotationResponse.builder()
                            .id(a.getId())
                            .paperId(a.getPaper().getId())
                            .userId(a.getUser().getId())
                            .annotationType(a.getAnnotationType())
                            .annotationDataJson(a.getAnnotationDataJson())
                            .pageNumber(a.getPageNumber())
                            .build()).toList()
            );

            AnnotationBackup backup = AnnotationBackup.builder()
                    .user(user)
                    .backupJson(backupJson)
                    .annotationCount(annotations.size())
                    .build();

            backup = annotationBackupRepository.save(backup);

            auditService.logInfo("ANNOTATION", "BACKUP_ANNOTATIONS",
                    user.getUsername(), "Backup created", "DEVICE");

            return AnnotationBackupResponse.builder()
                    .backupId(backup.getId())
                    .userId(userId)
                    .annotationCount(backup.getAnnotationCount())
                    .backupJson(backup.getBackupJson())
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("Failed to backup annotations");
        }
    }

    public String restore(AnnotationRestoreRequest request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        AnnotationBackup backup = annotationBackupRepository.findById(request.getBackupId())
                .orElseThrow(() -> new ResourceNotFoundException("Backup not found"));

        auditService.logInfo("ANNOTATION", "RESTORE_ANNOTATIONS",
                user.getUsername(), "Restore requested from backup " + backup.getId(), "DEVICE");

        return "Annotation restore completed from backup " + backup.getId();
    }

    private AnnotationResponse map(Annotation annotation) {
        return AnnotationResponse.builder()
                .id(annotation.getId())
                .paperId(annotation.getPaper().getId())
                .userId(annotation.getUser().getId())
                .annotationType(annotation.getAnnotationType())
                .annotationDataJson(annotation.getAnnotationDataJson())
                .pageNumber(annotation.getPageNumber())
                .build();
    }
}
