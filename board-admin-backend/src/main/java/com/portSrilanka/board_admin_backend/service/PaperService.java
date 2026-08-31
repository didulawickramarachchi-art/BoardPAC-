package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.paper.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    public PaperResponse create(PaperRequest request, String username) {

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

        User createdBy = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found"));

        AgendaItem agendaItem = null;
        if (request.getAgendaItemId() != null) {
            agendaItem = agendaItemRepository.findById(request.getAgendaItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Agenda item not found"));
        }

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

        List<MeetingParticipant> participants = meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meeting.getId());
        for (MeetingParticipant participant : participants) {
            packDeliveryRepository.save(
                    PackDelivery.builder()
                            .paper(paper)
                            .user(participant.getUser())
                            .deliveryStatus(DeliveryStatus.NOT_READ)
                            .build()
            );
        }

        notificationService.notifyPaperCreated(paper, participants, createdBy);

        auditService.logInfo("PAPER", "CREATE_PAPER", createdBy.getUsername(),
                "Paper created: " + paper.getTitle(), "WEB");

        return mapPaper(paper);
    }

    public List<PaperResponse> getByMeeting(Long meetingId) {
        return paperRepository.findByMeetingId(meetingId)
                .stream()
                .filter(Paper::isCurrentVersion)
                .map(this::mapPaper)
                .toList();
    }

    public List<PaperResponse> getAll() {
        return paperRepository.findAll()
                .stream()
                .filter(Paper::isCurrentVersion)
                .map(this::mapPaper)
                .toList();
    }

    public List<PaperResponse> getByAgendaItem(Long agendaItemId) {
        return paperRepository.findByAgendaItemId(agendaItemId)
                .stream()
                .filter(Paper::isCurrentVersion)
                .map(this::mapPaper)
                .toList();
    }

    public List<PaperResponse> versionHistory(Long paperId, String username, boolean secretary) {
        Paper paper = paperRepository.findById(paperId).orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        User user = userRepository.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (!secretary && meetingParticipantRepository.findByMeetingIdAndUserId(paper.getMeeting().getId(), user.getId()).isEmpty()) {
            throw new org.springframework.security.access.AccessDeniedException("Paper access denied");
        }
        Long rootId = paper.getRootPaper() == null ? paper.getId() : paper.getRootPaper().getId();
        return paperRepository.findVersionHistory(rootId).stream().map(this::mapPaper).toList();
    }

    @Transactional
    public PaperResponse createRevision(Long paperId, PaperRevisionRequest request, String username) {
        Paper previous = paperRepository.findById(paperId).orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        if (!previous.isCurrentVersion()) throw new BadRequestException("Create revisions from the current paper version");
        if (request.getFilePath() == null || request.getFilePath().isBlank()) throw new BadRequestException("A revised document is required");
        User creator = userRepository.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("Creator not found"));
        Paper root = previous.getRootPaper() == null ? previous : previous.getRootPaper();
        previous.setCurrentVersion(false);
        paperRepository.save(previous);
        Paper revision = paperRepository.save(Paper.builder().meeting(previous.getMeeting()).agendaItem(previous.getAgendaItem())
                .paperType(previous.getPaperType()).title(previous.getTitle()).referenceNumber(previous.getReferenceNumber())
                .filePath(request.getFilePath().trim()).fileName(request.getFileName()).versionNumber((previous.getVersionNumber() == null ? 1 : previous.getVersionNumber()) + 1)
                .requiresApproval(previous.isRequiresApproval()).isMainPaper(previous.isMainPaper()).disclaimerMessage(previous.getDisclaimerMessage())
                .rootPaper(root).currentVersion(true).revisionNote(request.getRevisionNote()).build());
        List<MeetingParticipant> participants = meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(previous.getMeeting().getId());
        for (MeetingParticipant participant : participants) packDeliveryRepository.save(PackDelivery.builder().paper(revision).user(participant.getUser()).deliveryStatus(DeliveryStatus.NOT_READ).build());
        notificationService.notifyPaperCreated(revision, participants, creator);
        auditService.logInfo("PAPER", "CREATE_REVISION", username, "Paper " + paperId + " revised to version " + revision.getVersionNumber(), "WEB");
        return mapPaper(revision);
    }

    public String markRead(Long paperId, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        PackDelivery delivery = packDeliveryRepository.findByPaperIdAndUserId(paperId, user.getId())
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
            sharedBy.getUsername(),
            paper.getId()
    );

    auditService.logInfo("PAPER", "SHARE_PAPER",
            sharedBy.getUsername(),
            "Paper shared to " + sharedTo.getUsername(), "DEVICE");

    return "Paper shared successfully";
}
    private PaperResponse mapPaper(Paper paper) {
        return PaperResponse.builder()
                .id(paper.getId())
                .agendaItemId(paper.getAgendaItem() != null ? paper.getAgendaItem().getId() : null)
                .title(paper.getTitle())
                .paperType(paper.getPaperType())
                .referenceNumber(paper.getReferenceNumber())
                .filePath(paper.getFilePath())
                .fileName(paper.getFileName())
                .versionNumber(paper.getVersionNumber())
                .requiresApproval(paper.isRequiresApproval())
                .isMainPaper(paper.isMainPaper())
                .rootPaperId(paper.getRootPaper() == null ? paper.getId() : paper.getRootPaper().getId())
                .currentVersion(paper.isCurrentVersion())
                .revisionNote(paper.getRevisionNote())
                .createdAt(paper.getCreatedAt())
                .build();
    }
}


