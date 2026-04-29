package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PaperService {

    private final MeetingRepository meetingRepository;
    private final AgendaItemRepository agendaItemRepository;
    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final PaperShareRepository paperShareRepository;
    private final PackDeliveryRepository packDeliveryRepository;
    private final MeetingParticipantRepository meetingParticipantRepository;
    private final AuditService auditService;
    private final WorkflowSettingService workflowSettingService;
    private final NotificationService notificationService;

    public PaperResponse create(PaperRequest request) {

        workflowSettingService.validateReferenceNumber(request.getReferenceNumber());

        boolean uniqueRef = workflowSettingService.isEnabled("UNIQUE_PAPER_REFERENCE_NUMBER", false);

        if (uniqueRef
                && request.getReferenceNumber() != null
                && !request.getReferenceNumber().isBlank()) {

            paperRepository.findByReferenceNumber(request.getReferenceNumber())
                    .ifPresent(existing -> {
                        throw new BadRequestException("Paper reference number must be unique");
                    });
        }

        Meeting meeting = meetingRepository.findById(request.getMeetingId())
                .orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));

        AgendaItem agendaItem = agendaItemRepository.findById(request.getAgendaItemId())
                .orElseThrow(() -> new ResourceNotFoundException("Agenda item not found"));

        Paper paper = Paper.builder()
                .meeting(meeting)
                .agendaItem(agendaItem)
                .paperType(request.getPaperType())
                .title(request.getTitle())
                .referenceNumber(request.getReferenceNumber())
                .filePath(request.getFilePath())
                .fileName(request.getFileName())
                .versionNumber(request.getVersionNumber())
                .requiresApproval(request.isRequiresApproval())
                .isMainPaper(request.isMainPaper())
                .disclaimerMessage(request.getDisclaimerMessage())
                .build();

        paper = paperRepository.save(paper);

        for (MeetingParticipant participant : meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meeting.getId())) {
            packDeliveryRepository.save(
                    PackDelivery.builder()
                            .paper(paper)
                            .user(participant.getUser())
                            .deliveryStatus(DeliveryStatus.NOT_READ)
                            .build()
            );
        }

        auditService.logInfo("PAPER", "CREATE_PAPER", "SYSTEM",
                "Paper created: " + paper.getTitle(), "WEB");

        return mapPaper(paper);
    }

    public List<PaperResponse> getByMeeting(Long meetingId) {
        return paperRepository.findByMeetingId(meetingId)
                .stream()
                .map(this::mapPaper)
                .toList();
    }

    public List<PaperResponse> getByAgendaItem(Long agendaItemId) {
        return paperRepository.findByAgendaItemId(agendaItemId)
                .stream()
                .map(this::mapPaper)
                .toList();
    }

    public String markRead(Long paperId, Long userId) {
        PackDelivery delivery = packDeliveryRepository.findByPaperIdAndUserId(paperId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Pack delivery record not found"));

        delivery.setDeliveryStatus(DeliveryStatus.READ);
        packDeliveryRepository.save(delivery);

        return "Paper marked as read";
    }

    public String sharePaper(SharePaperRequest request) {
    Paper paper = paperRepository.findById(request.getPaperId())
            .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));

    User sharedBy = userRepository.findById(request.getSharedByUserId())
            .orElseThrow(() -> new ResourceNotFoundException("Shared by user not found"));

    User sharedTo = userRepository.findById(request.getSharedToUserId())
            .orElseThrow(() -> new ResourceNotFoundException("Shared to user not found"));

    paperShareRepository.save(
            PaperShare.builder()
                    .paper(paper)
                    .sharedBy(sharedBy)
                    .sharedTo(sharedTo)
                    .build()
    );

    notificationService.notifyAnnotatedPaperShared(
            sharedTo,
            paper.getTitle(),
            sharedBy.getUsername()
    );

    auditService.logInfo("PAPER", "SHARE_PAPER",
            sharedBy.getUsername(),
            "Paper shared to " + sharedTo.getUsername(), "DEVICE");

    return "Paper shared successfully";
}
    private PaperResponse mapPaper(Paper paper) {
        return PaperResponse.builder()
                .id(paper.getId())
                .title(paper.getTitle())
                .paperType(paper.getPaperType())
                .referenceNumber(paper.getReferenceNumber())
                .filePath(paper.getFilePath())
                .fileName(paper.getFileName())
                .versionNumber(paper.getVersionNumber())
                .requiresApproval(paper.isRequiresApproval())
                .isMainPaper(paper.isMainPaper())
                .build();
    }
}