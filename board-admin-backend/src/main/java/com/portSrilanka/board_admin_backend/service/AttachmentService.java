package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.PaperAttachment;
import com.portSrilanka.board_admin_backend.entity.AttachmentReaction;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import com.portSrilanka.board_admin_backend.enums.ReactionType;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.PaperAttachmentRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import com.portSrilanka.board_admin_backend.repository.AttachmentReactionRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.repository.MeetingParticipantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AttachmentService {

    private final PaperRepository paperRepository;
    private final PaperAttachmentRepository paperAttachmentRepository;
    private final AuditService auditService;
    private final AttachmentReactionRepository attachmentReactionRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final MeetingParticipantRepository meetingParticipantRepository;

    public PaperAttachmentResponse addAttachment(PaperAttachmentRequest request, String username) {
        Paper paper = paperRepository.findById(request.getPaperId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        User createdBy = findUser(username);

        PaperAttachment attachment = PaperAttachment.builder()
                .paper(paper)
                .fileName(request.getFileName())
                .filePath(request.getFilePath())
                .displayOrder(request.getDisplayOrder())
                .build();

        attachment = paperAttachmentRepository.save(attachment);
        notificationService.notifyDocumentUploaded(
                attachment,
                meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(paper.getMeeting().getId()),
                createdBy
        );

        auditService.logInfo("PAPER", "ADD_ATTACHMENT", createdBy.getUsername(),
                "Attachment added to paper " + paper.getTitle(), "WEB");

        return map(attachment, null);
    }

    public List<PaperAttachmentResponse> getAttachments(Long paperId, String username) {
        User user = findUser(username);
        return paperAttachmentRepository.findByPaperIdOrderByDisplayOrderAsc(paperId)
                .stream()
                .map(attachment -> map(attachment, user.getId()))
                .toList();
    }

    public PaperAttachmentResponse react(Long attachmentId, ReactionType type, String username) {
        PaperAttachment attachment = paperAttachmentRepository.findById(attachmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Attachment not found"));
        User user = findUser(username);
        AttachmentReaction existing = attachmentReactionRepository
                .findByAttachmentIdAndUserId(attachmentId, user.getId()).orElse(null);
        if (existing != null && existing.getReactionType() == type) {
            attachmentReactionRepository.delete(existing);
        } else if (existing != null) {
            existing.setReactionType(type);
            attachmentReactionRepository.save(existing);
        } else {
            attachmentReactionRepository.save(AttachmentReaction.builder()
                    .attachment(attachment).user(user).reactionType(type).build());
        }
        return map(attachment, user.getId());
    }

    private User findUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private PaperAttachmentResponse map(PaperAttachment attachment, Long currentUserId) {
        List<AttachmentReaction> reactions = attachmentReactionRepository
                .findByAttachmentId(attachment.getId());
        java.util.Map<String, Long> counts = new java.util.HashMap<>();
        for (ReactionType type : ReactionType.values()) {
            counts.put(type.name(), reactions.stream()
                    .filter(reaction -> reaction.getReactionType() == type).count());
        }
        AttachmentReaction current = currentUserId == null ? null : reactions.stream()
                .filter(reaction -> reaction.getUser().getId().equals(currentUserId))
                .findFirst().orElse(null);
        return PaperAttachmentResponse.builder()
                .id(attachment.getId())
                .paperId(attachment.getPaper().getId())
                .fileName(attachment.getFileName())
                .filePath(attachment.getFilePath())
                .displayOrder(attachment.getDisplayOrder())
                .currentReaction(current != null ? current.getReactionType().name() : null)
                .reactionCounts(counts)
                .build();
    }
}




