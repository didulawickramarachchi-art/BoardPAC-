package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.PaperAttachment;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.PaperAttachmentRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AttachmentService {

    private final PaperRepository paperRepository;
    private final PaperAttachmentRepository paperAttachmentRepository;
    private final AuditService auditService;

    public PaperAttachmentResponse addAttachment(PaperAttachmentRequest request) {
        Paper paper = paperRepository.findById(request.getPaperId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));

        PaperAttachment attachment = PaperAttachment.builder()
                .paper(paper)
                .fileName(request.getFileName())
                .filePath(request.getFilePath())
                .displayOrder(request.getDisplayOrder())
                .build();

        attachment = paperAttachmentRepository.save(attachment);

        auditService.logInfo("PAPER", "ADD_ATTACHMENT", "SYSTEM",
                "Attachment added to paper " + paper.getTitle(), "WEB");

        return map(attachment);
    }

    public List<PaperAttachmentResponse> getAttachments(Long paperId) {
        return paperAttachmentRepository.findByPaperIdOrderByDisplayOrderAsc(paperId)
                .stream()
                .map(this::map)
                .toList();
    }

    private PaperAttachmentResponse map(PaperAttachment attachment) {
        return PaperAttachmentResponse.builder()
                .id(attachment.getId())
                .paperId(attachment.getPaper().getId())
                .fileName(attachment.getFileName())
                .filePath(attachment.getFilePath())
                .displayOrder(attachment.getDisplayOrder())
                .build();
    }
}