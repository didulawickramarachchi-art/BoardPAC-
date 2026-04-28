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

    public ApprovalResponse approve(ApprovalRequest request) {
        Paper paper = paperRepository.findById(request.getPaperId())
                .orElseThrow(() -> new ResourceNotFoundException("Paper not found"));
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!paper.isRequiresApproval()) {
            throw new BadRequestException("This paper does not require approval");
        }

        PaperApproval approval = paperApprovalRepository.findByPaperIdAndUserId(paper.getId(), user.getId())
                .orElse(PaperApproval.builder()
                        .paper(paper)
                        .user(user)
                        .build());

        approval.setApprovalStatus(request.getApprovalStatus());
        approval.setApprovalComment(request.getApprovalComment());
        approval = paperApprovalRepository.save(approval);

        auditService.logInfo("APPROVAL", "SET_APPROVAL",
                user.getUsername(),
                "Approval=" + request.getApprovalStatus() + " for paper " + paper.getTitle(),
                "DEVICE");

        return ApprovalResponse.builder()
                .id(approval.getId())
                .userId(user.getId())
                .username(user.getUsername())
                .approvalStatus(approval.getApprovalStatus())
                .approvalComment(approval.getApprovalComment())
                .build();
    }

    public List<ApprovalResponse> getByPaper(Long paperId) {
        return paperApprovalRepository.findByPaperId(paperId)
                .stream()
                .map(approval -> ApprovalResponse.builder()
                        .id(approval.getId())
                        .userId(approval.getUser().getId())
                        .username(approval.getUser().getUsername())
                        .approvalStatus(approval.getApprovalStatus())
                        .approvalComment(approval.getApprovalComment())
                        .build())
                .toList();
    }
}
