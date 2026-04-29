package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.report.*;
import com.portSrilanka.board_admin_backend.entity.PaperApproval;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.entity.UserSubcategoryAccess;
import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.PaperApprovalRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import com.portSrilanka.board_admin_backend.repository.UserSubcategoryAccessRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminReportService {

    private final UserSubcategoryAccessRepository accessRepository;
    private final UserRepository userRepository;
    private final PaperApprovalRepository paperApprovalRepository;

    public List<UserCategoryReportResponse> userCategoryReport() {
        return accessRepository.findAll().stream()
                .map(this::mapAccess)
                .toList();
    }

    public LicenseUtilizationResponse licenseUtilization() {
        List<User> users = userRepository.findAll();

        return LicenseUtilizationResponse.builder()
                .totalUsers(users.size())
                .activeUsers(users.stream().filter(u -> u.getStatus() == UserStatus.ACTIVE).count())
                .deactivatedUsers(users.stream().filter(u -> u.getStatus() == UserStatus.DEACTIVATED).count())
                .lockedUsers(users.stream().filter(u -> u.getStatus() == UserStatus.LOCKED).count())
                .deletedUsers(users.stream().filter(u -> u.getStatus() == UserStatus.DELETED).count())
                .build();
    }

    public List<PendingApprovalReportResponse> pendingApprovalReport() {
        return paperApprovalRepository.findAll().stream()
                .filter(pa -> pa.getApprovalStatus() == ApprovalStatus.PENDING)
                .map(this::mapPending)
                .toList();
    }

    private UserCategoryReportResponse mapAccess(UserSubcategoryAccess a) {
        return UserCategoryReportResponse.builder()
                .userId(a.getUser().getId())
                .username(a.getUser().getUsername())
                .categoryName(a.getSubcategory().getCategory().getName())
                .subcategoryName(a.getSubcategory().getName())
                .assignedRole(a.getAssignedRole())
                .build();
    }

    private PendingApprovalReportResponse mapPending(PaperApproval pa) {
        return PendingApprovalReportResponse.builder()
                .paperId(pa.getPaper().getId())
                .paperTitle(pa.getPaper().getTitle())
                .userId(pa.getUser().getId())
                .username(pa.getUser().getUsername())
                .meetingTitle(pa.getPaper().getMeeting().getTitle())
                .build();
    }
}
