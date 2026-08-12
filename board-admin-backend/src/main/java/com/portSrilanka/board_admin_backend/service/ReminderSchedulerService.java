package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.PaperApproval;
import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import com.portSrilanka.board_admin_backend.enums.ApprovalStatus;
import com.portSrilanka.board_admin_backend.enums.MeetingType;
import com.portSrilanka.board_admin_backend.repository.MeetingParticipantRepository;
import com.portSrilanka.board_admin_backend.repository.MeetingRepository;
import com.portSrilanka.board_admin_backend.repository.PaperApprovalRepository;
import com.portSrilanka.board_admin_backend.repository.PaperRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReminderSchedulerService {

    private final MeetingRepository meetingRepository;
    private final PaperRepository paperRepository;
    private final PaperApprovalRepository paperApprovalRepository;
    private final MeetingParticipantRepository meetingParticipantRepository;
    private final EmailService emailService;
    private final NotificationService notificationService;
    private final WorkflowSettingService workflowSettingService;

    @Scheduled(cron = "0 0/30 * * * *")
    public void sendUnapprovedPaperAlerts() {
        List<Meeting> meetings = meetingRepository.findAll();

        for (Meeting meeting : meetings) {
            if (meeting.getType() == MeetingType.MEETING) {
                processMeeting(meeting, "LEAD_TIME_PRIOR_TO_MEETING_DATE_EMAIL_ALERTS");
                processMeetingForReminder(meeting);
            } else {
                processMeeting(meeting, "LEAD_TIME_PRIOR_TO_CIRCULAR_TARGET_DATE_EMAIL_ALERTS");
                processMeetingForReminder(meeting);
            }
        }
    }

    private void processMeetingForReminder(Meeting meeting) {
        LocalDateTime referenceTime = meeting.getType() == MeetingType.MEETING
                ? meeting.getMeetingDateTime()
                : meeting.getTargetDateTime();

        if (referenceTime == null) return;

        LocalDateTime reminderTime = referenceTime.minusHours(24);
        LocalDateTime now = LocalDateTime.now();

        // if within 30 minutes window after the exact reminder time, send reminder
        if (!now.isBefore(reminderTime) && now.isBefore(reminderTime.plusMinutes(30))) {
            List<MeetingParticipant> participants = meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meeting.getId());
            try {
                notificationService.notifyMeetingReminder(meeting, participants);
            } catch (Exception ex) {
                // swallow to avoid scheduled task failure
            }
        }
    }

    private void processMeeting(Meeting meeting, String settingKey) {
        int leadMinutes = Integer.parseInt(workflowSettingService.getValue(settingKey, "60"));
        LocalDateTime referenceTime = meeting.getType() == MeetingType.MEETING
                ? meeting.getMeetingDateTime()
                : meeting.getTargetDateTime();

        if (referenceTime == null) return;

        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(referenceTime.minusMinutes(leadMinutes)) || now.isAfter(referenceTime)) {
            return;
        }

        List<Paper> papers = paperRepository.findByMeetingId(meeting.getId());

        for (MeetingParticipant participant : meetingParticipantRepository.findByMeetingIdOrderByDisplaySequenceAsc(meeting.getId())) {
            boolean hasPending = false;

            for (Paper paper : papers) {
                if (!paper.isRequiresApproval()) continue;

                PaperApproval approval = paperApprovalRepository.findByPaperIdAndUserId(paper.getId(), participant.getUser().getId())
                        .orElse(null);

                if (approval == null || approval.getApprovalStatus() == ApprovalStatus.PENDING) {
                    hasPending = true;
                    break;
                }
            }

            if (hasPending) {
                emailService.sendEmail(
                        participant.getUser().getBoardEmail(),
                        "Pending paper approvals",
                        "You have pending approvals for " + meeting.getTitle()
                );
            }
        }
    }
}