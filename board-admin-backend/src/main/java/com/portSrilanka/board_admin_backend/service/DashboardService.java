package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.dashboard.DashboardSummaryResponse;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.DeliveryStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import com.portSrilanka.board_admin_backend.enums.MeetingStatus;
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
    private final PackDeliveryRepository packDeliveryRepository;
    private final CommentShareRepository commentShareRepository;
    private final PaperShareRepository paperShareRepository;
    private final UserRepository userRepository;
    private final MeetingParticipantRepository meetingParticipantRepository;
    private final UserSubcategoryAccessRepository accessRepository;

    public DashboardSummaryResponse getSummaryForUser(Long userId, String username) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!user.getUsername().equals(username)) {
            throw new AccessDeniedException("Cannot view another user's dashboard");
        }

        List<Meeting> visibleMeetings = getVisibleMeetings(user);
        long totalMeetings = visibleMeetings.stream()
                .filter(meeting -> meeting.getType() == MeetingType.MEETING)
                .count();
        long totalCirculars = visibleMeetings.stream()
                .filter(meeting -> meeting.getType() == MeetingType.CIRCULAR)
                .count();

        LocalDateTime now = LocalDateTime.now();
        Meeting upcomingMeeting = getUpcomingMeetingCandidates(user).stream()
                .filter(meeting -> meeting.getType() == MeetingType.MEETING)
                .filter(meeting -> meeting.getStatus() != MeetingStatus.CANCELLED)
                .filter(meeting -> !meeting.getMeetingDateTime().isBefore(now))
                .min(Comparator.comparing(Meeting::getMeetingDateTime))
                .orElse(null);

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

        return meetingRepository.findAll().stream()
                .filter(meeting -> privilegedSubcategoryIds.contains(meeting.getSubcategory().getId()))
                .filter(meeting -> meetingParticipantRepository
                        .findByMeetingIdAndUserId(meeting.getId(), user.getId())
                        .isPresent())
                .toList();
    }

    private List<Meeting> getUpcomingMeetingCandidates(User user) {
        boolean isSecretary = user.getRoles().stream()
                .anyMatch(role -> "SECRETARY".equals(role.getName().authorityName()));
        if (isSecretary) {
            return meetingRepository.findAll();
        }

        return meetingRepository.findAll().stream()
                .filter(meeting -> meetingParticipantRepository
                        .findByMeetingIdAndUserId(meeting.getId(), user.getId())
                        .isPresent())
                .toList();
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
