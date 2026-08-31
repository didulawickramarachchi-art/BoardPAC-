package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.approval.*;
import com.portSrilanka.board_admin_backend.entity.*;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ApprovalService {

    private final PaperRepository paperRepository;
    private final UserRepository userRepository;
    private final PaperApprovalRepository paperApprovalRepository;
    private final AuditService auditService;
    private final WorkflowSettingService workflowSettingService;
    private final NotificationService notificationService;
    private final MeetingParticipantRepository meetingParticipantRepository;

    public ApprovalResponse approve(ApprovalRequest request, String username) {

        workflowSettingService.validateApprovalComment(request.getApprovalComment());

        Paper paper = paperRepository.findById(request.getPaperId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (paper.getMeeting() != null && meetingParticipantRepository
                .findByMeetingIdAndUserId(paper.getMeeting().getId(), user.getId()).isEmpty()) {
            throw new org.springframework.security.access.AccessDeniedException("Only meeting participants can approve this paper");
        }

        boolean blockMeetingApprovals =
                workflowSettingService.isEnabled("BLOCK_APPROVALS_FOR_MEETING_PAPERS_ONLY", false);

        if (blockMeetingApprovals
                && paper.getMeeting() != null
                && paper.getMeeting().getType() != null
                && paper.getMeeting().getType().name().equals("MEETING")) {

            throw new BadRequestException("Approvals for meeting papers are blocked by settings");
        }

        if (!paper.isRequiresApproval()) {
            throw new BadRequestException("This paper does not require approval");
        }

        PaperApproval approval = paperApprovalRepository
                .findByPaperIdAndUserId(paper.getId(), user.getId())
                .orElse(PaperApproval.builder()
                        .paper(paper)
                        .user(user)
                        .build());

        approval.setApprovalStatus(request.getApprovalStatus());
        approval.setApprovalComment(request.getApprovalComment());

        approval = paperApprovalRepository.save(approval);

        notificationService.notifyApproval(
                user,
                paper,
                request.getApprovalStatus().name()
        );

        auditService.logInfo("APPROVAL", "SET_APPROVAL",
                user.getUsername(),
                "Approval=" + request.getApprovalStatus() + " for paper " + paper.getTitle(),
                "DEVICE");

        return map(approval, user.getId());
    }

    public List<ApprovalResponse> getByPaper(Long paperId, String username, boolean canSeeAll) {
        User current = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return paperApprovalRepository.findByPaperId(paperId)
                .stream()
                .filter(approval -> canSeeAll || approval.getUser().getId().equals(current.getId()))
                .map(approval -> map(approval, current.getId()))
                .toList();
    }

    private ApprovalResponse map(PaperApproval approval, Long currentUserId) {
        return ApprovalResponse.builder().id(approval.getId()).userId(approval.getUser().getId())
                .username(approval.getUser().getUsername()).approvalStatus(approval.getApprovalStatus())
                .approvalComment(approval.getApprovalComment()).createdAt(approval.getCreatedAt())
                .updatedAt(approval.getUpdatedAt()).ownedByCurrentUser(approval.getUser().getId().equals(currentUserId)).build();
    }
}
