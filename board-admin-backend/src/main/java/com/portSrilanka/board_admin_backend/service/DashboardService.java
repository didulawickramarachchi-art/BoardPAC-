package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.dashboard.DashboardSummaryResponse;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.DeviceStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final MeetingRepository meetingRepository;
    private final PaperApprovalRepository paperApprovalRepository;
    private final PaperRepository paperRepository;
    private final PackDeliveryRepository packDeliveryRepository;
    private final CommentShareRepository commentShareRepository;
    private final PaperShareRepository paperShareRepository;
    private final UserRepository userRepository;
    private final UserSubcategoryAccessRepository accessRepository;
    private final DeviceRepository deviceRepository;

    public DashboardSummaryResponse getSummaryForUser(Long userId, String username) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!user.getUsername().equals(username)) {
            throw new AccessDeniedException("Cannot view another user's dashboard");
        }

        boolean isSecretary = hasRole(user, "SECRETARY");
        boolean isMember = hasRole(user, "MEMBER");
        boolean isAdmin = hasRole(user, "ADMIN");
        boolean seesAllMeetings = isSecretary || !isMember;
        List<Meeting> visibleMeetings = seesAllMeetings ? List.of() : getVisibleMeetings(user);
        long totalMeetings = seesAllMeetings
                ? meetingRepository.countByType(MeetingType.MEETING)
                : countType(visibleMeetings, MeetingType.MEETING);
        long totalCirculars = seesAllMeetings
                ? meetingRepository.countByType(MeetingType.CIRCULAR)
                : countType(visibleMeetings, MeetingType.CIRCULAR);

        LocalDateTime now = LocalDateTime.now();
        // Admin does not render upcoming-meeting data. Avoid the former
        // participant lookup per meeting (an expensive N+1 query) entirely.
        List<Meeting> upcomingCandidates = isAdmin
                ? List.of()
                : isSecretary ? meetingRepository.findAll() : visibleMeetings;
        Meeting upcomingMeeting = upcomingCandidates.stream()
                .filter(meeting -> meeting.getType() == MeetingType.MEETING)
                .filter(meeting -> meeting.getStatus() != MeetingStatus.CANCELLED)
                .filter(meeting -> meeting.getStatus() != MeetingStatus.CLOSED)
                .filter(meeting -> meeting.getStatus() != MeetingStatus.LAST)
                .filter(meeting -> meeting.getMeetingDateTime().isAfter(now))
                .min(Comparator.comparing(Meeting::getMeetingDateTime))
                .orElse(null);

        List<Long> visibleMeetingIds = visibleMeetings.stream()
                .map(Meeting::getId)
                .toList();
        long pendingApprovals = !isMember || visibleMeetingIds.isEmpty()
                ? 0
                : paperRepository.countPendingApprovalsForUser(
                        userId,
                        visibleMeetingIds,
                        Set.of(
                                ApprovalStatus.APPROVE,
                                ApprovalStatus.REJECT,
                                ApprovalStatus.ABSTAIN,
                                ApprovalStatus.INTEREST,
                                ApprovalStatus.RPT
                        )
                );

        // Let PostgreSQL count these rows instead of loading whole entity graphs.
        long unreadPapers = packDeliveryRepository
                .countByUserIdAndDeliveryStatus(userId, DeliveryStatus.NOT_READ);
        long sharedComments = commentShareRepository.countBySharedToId(userId);
        long sharedDocuments = paperShareRepository.countBySharedToId(userId);

        return DashboardSummaryResponse.builder()
                .totalUsers(userRepository.count())
                .totalMembers(userRepository.countDistinctByRolesName(SystemRole.MEMBER))
                .totalSecretaries(userRepository.countDistinctByRolesName(SystemRole.SECRETARY))
                .totalAdmins(userRepository.countDistinctByRolesName(SystemRole.ADMIN))
                .pendingDevices(deviceRepository.countByStatus(DeviceStatus.PENDING))
                .totalMeetings(totalMeetings)
                .totalCirculars(totalCirculars)
                .pendingApprovals(pendingApprovals)
                .unreadPapers(unreadPapers)
                .sharedComments(sharedComments)
                .sharedDocuments(sharedDocuments)
                .upcomingMeetingTitle(
                        upcomingMeeting != null ? upcomingMeeting.getTitle() : null
                )
                .upcomingMeetingDateTime(
                        upcomingMeeting != null ? upcomingMeeting.getMeetingDateTime() : null
                )
                .upcomingMeetingLocation(
                        upcomingMeeting != null ? upcomingMeeting.getLocation() : null
                )
                .upcomingMeetingDaysText(getUpcomingDaysText(upcomingMeeting, now))
                .build();
    }

    private boolean hasRole(User user, String role) {
        return user.getRoles().stream()
                .anyMatch(value -> role.equals(value.getName().authorityName()));
    }

    private long countType(List<Meeting> meetings, MeetingType type) {
        return meetings.stream().filter(meeting -> meeting.getType() == type).count();
    }

    private List<Meeting> getVisibleMeetings(User user) {
        boolean isSecretary = user.getRoles().stream()
                .anyMatch(role -> "SECRETARY".equals(role.getName().authorityName()));
        boolean isMember = user.getRoles().stream()
                .anyMatch(role -> "MEMBER".equals(role.getName().authorityName()));

        if (isSecretary || !isMember) {
            return meetingRepository.findAll();
        }

        Set<Long> privilegedSubcategoryIds = accessRepository.findByUserId(user.getId())
                .stream()
                .map(access -> access.getSubcategory().getId())
                .collect(java.util.stream.Collectors.toSet());
        if (privilegedSubcategoryIds.isEmpty()) {
            return List.of();
        }

        return meetingRepository.findVisibleForMember(user.getId(), privilegedSubcategoryIds);
    }

    private String getUpcomingDaysText(Meeting meeting, LocalDateTime now) {
        if (meeting == null) {
            return null;
        }

        long days = ChronoUnit.DAYS.between(now.toLocalDate(), meeting.getMeetingDateTime().toLocalDate());
        if (days == 0) {
            return "Today";
        }
        if (days == 1) {
            return "Tomorrow";
        }
        return "In " + days + " days";
    }
}
