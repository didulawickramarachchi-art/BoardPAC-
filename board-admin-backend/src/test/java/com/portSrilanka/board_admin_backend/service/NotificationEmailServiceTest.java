package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.PaperAttachment;
import com.portSrilanka.board_admin_backend.entity.Role;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.repository.NotificationReactionRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationReplyRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class NotificationEmailServiceTest {

    private EmailService emailService;
    private NotificationRepository notificationRepository;
    private NotificationService service;
    private User member;
    private Meeting meeting;
    private List<MeetingParticipant> participants;

    @BeforeEach
    void setUp() {
        emailService = mock(EmailService.class);
        notificationRepository = mock(NotificationRepository.class);
        service = new NotificationService(
                emailService,
                mock(WorkflowSettingService.class),
                notificationRepository,
                mock(NotificationReplyRepository.class),
                mock(NotificationReactionRepository.class),
                mock(UserRepository.class)
        );
        Role memberRole = Role.builder().name(SystemRole.MEMBER).build();
        member = User.builder()
                .username("kamal")
                .firstName("Kamal")
                .boardEmail("kamal@example.com")
                .status(UserStatus.ACTIVE)
                .roles(Set.of(memberRole))
                .build();
        member.setId(10L);
        meeting = Meeting.builder()
                .title("Board Meeting")
                .meetingDateTime(LocalDateTime.of(2026, 10, 1, 9, 0))
                .createdBy(member)
                .build();
        meeting.setId(20L);
        participants = List.of(MeetingParticipant.builder().meeting(meeting).user(member).build());
    }

    @Test
    void meetingCreationEmailsActiveMemberParticipants() {
        service.notifyMeetingCreated(meeting, participants);

        verify(emailService).sendEmail(
                eq("kamal@example.com"),
                eq("New meeting: Board Meeting"),
                contains("Date and time")
        );
    }

    @Test
    void paperAndAttachmentCreationEmailParticipants() {
        Paper paper = Paper.builder().title("Budget").meeting(meeting).build();
        paper.setId(30L);
        PaperAttachment attachment = PaperAttachment.builder()
                .paper(paper).fileName("appendix.pdf").build();
        attachment.setId(40L);

        service.notifyPaperCreated(paper, participants, member);
        service.notifyDocumentUploaded(attachment, participants, member);

        verify(emailService).sendEmail(
                eq("kamal@example.com"), eq("New paper: Budget"), contains("Approval required"));
        verify(emailService).sendEmail(
                eq("kamal@example.com"), eq("New attachment: appendix.pdf"), contains("Budget"));
    }

    @Test
    void meetingReminderIsSentOnlyOncePerMemberAndMeeting() {
        when(notificationRepository.existsByRecipientIdAndTypeAndRelatedMeetingId(
                10L, "MEETING_REMINDER", 20L)).thenReturn(false, true);

        service.notifyMeetingReminder(meeting, participants);
        service.notifyMeetingReminder(meeting, participants);

        verify(emailService).sendEmail(
                eq("kamal@example.com"), eq("Meeting reminder: Board Meeting"), contains("next 24 hours"));
    }

    @Test
    void usersWithoutAnEmailAreSkipped() {
        member.setBoardEmail(" ");

        service.notifyMeetingCreated(meeting, participants);

        verify(emailService, never()).sendEmail(
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyString());
    }
}
