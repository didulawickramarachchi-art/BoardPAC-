package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.dashboard.DashboardSummaryResponse;
import com.portSrilanka.board_admin_backend.entity.PackDelivery;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final MeetingRepository meetingRepository;
    private final PaperApprovalRepository paperApprovalRepository;
    private final PackDeliveryRepository packDeliveryRepository;
    private final CommentShareRepository commentShareRepository;
    private final PaperShareRepository paperShareRepository;

    public DashboardSummaryResponse getSummaryForUser(Long userId) {
        long totalMeetings = meetingRepository.findByType(MeetingType.MEETING).size();
        long totalCirculars = meetingRepository.findByType(MeetingType.CIRCULAR).size();

        long pendingApprovals = paperApprovalRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(userId))
                .filter(a -> a.getApprovalStatus().name().equals("PENDING"))
                .count();

        long unreadPapers = packDeliveryRepository.findByUserId(userId).stream()
                .filter(pd -> pd.getDeliveryStatus() == DeliveryStatus.NOT_READ)
                .count();

        long sharedComments = commentShareRepository.findBySharedToId(userId).size();
        long sharedDocuments = paperShareRepository.findBySharedToId(userId).size();

        return DashboardSummaryResponse.builder()
                .totalMeetings(totalMeetings)
                .totalCirculars(totalCirculars)
                .pendingApprovals(pendingApprovals)
                .unreadPapers(unreadPapers)
                .sharedComments(sharedComments)
                .sharedDocuments(sharedDocuments)
                .build();
    }
}