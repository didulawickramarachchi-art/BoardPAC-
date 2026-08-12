package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.dto.notification.NotificationRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationReactionRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationReplyRequest;
import com.portSrilanka.board_admin_backend.dto.notification.NotificationResponse;
import com.portSrilanka.board_admin_backend.entity.BoardNotification;
import com.portSrilanka.board_admin_backend.entity.Meeting;
import com.portSrilanka.board_admin_backend.entity.MeetingParticipant;
import com.portSrilanka.board_admin_backend.entity.NotificationReaction;
import com.portSrilanka.board_admin_backend.entity.NotificationReply;
import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.PaperAttachment;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.UserStatus;
import com.portSrilanka.board_admin_backend.exception.ResourceNotFoundException;
import com.portSrilanka.board_admin_backend.repository.NotificationReactionRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationRepository;
import com.portSrilanka.board_admin_backend.repository.NotificationReplyRepository;
import com.portSrilanka.board_admin_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final EmailService emailService;
    private final WorkflowSettingService workflowSettingService;
    private final NotificationRepository notificationRepository;
    private final NotificationReplyRepository replyRepository;
    private final NotificationReactionRepository reactionRepository;
    private final UserRepository userRepository;

    public List<NotificationResponse> getForUser(Long userId) {
        return notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(notification -> map(notification, userId))
                .toList();
    }

    @Transactional
    public void markAllRead(Long userId) {
        List<BoardNotification> notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId);
        notifications.forEach(notification -> notification.setRead(true));
        notificationRepository.saveAll(notifications);
    }

    @Transactional
    public void clearForUser(Long userId) {
        notificationRepository.deleteAll(notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId));
    }

    @Transactional
    public NotificationResponse reply(Long notificationId, NotificationReplyRequest request, String username) {
        BoardNotification notification = findNotification(notificationId);
        User user = findUser(username);
        String message = clean(request.getMessage(), "");
        if (message.isEmpty()) {
            throw new IllegalArgumentException("Reply message is required");
        }

        replyRepository.save(NotificationReply.builder()
                .notification(notification)
                .user(user)
                .message(message)
                .build());

        return map(notificationRepository.findById(notificationId).orElse(notification), user.getId());
    }

    @Transactional
    public NotificationResponse react(Long notificationId, NotificationReactionRequest request, String username) {
        BoardNotification notification = findNotification(notificationId);
        User user = findUser(username);
        String reactionType = clean(request.getReactionType(), "LIKE").toUpperCase();
        NotificationReaction existing = reactionRepository
                .findByNotificationIdAndUserId(notificationId, user.getId())
                .orElse(null);

        if (existing != null && existing.getReactionType().equals(reactionType)) {
            reactionRepository.delete(existing);
        } else if (existing != null) {
            existing.setReactionType(reactionType);
            reactionRepository.save(existing);
        } else {
            reactionRepository.save(NotificationReaction.builder()
                    .notification(notification)
                    .user(user)
                    .reactionType(reactionType)
                    .build());
        }

        return map(notificationRepository.findById(notificationId).orElse(notification), user.getId());
    }

    @Transactional
    public void createAnnouncement(NotificationRequest request, String username) {
        User createdBy = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found"));

        List<User> recipients = userRepository.findAll()
                .stream()
                .filter(user -> user.getStatus() == UserStatus.ACTIVE)
                .toList();

        createForRecipients(
                recipients,
                createdBy,
                clean(request.getTitle(), "Announcement"),
                clean(request.getMessage(), ""),
                "ANNOUNCEMENT",
                null,
                null,
                null,
                null,
                true
        );
    }

    @Transactional
    public void notifyMeetingCreated(Meeting meeting, List<MeetingParticipant> participants) {
        createForRecipients(
                participants.stream().map(MeetingParticipant::getUser).toList(),
                meeting.getCreatedBy(),
                "New meeting created",
                meeting.getTitle() + " has been added to the board schedule.",
                "MEETING_CREATED",
                meeting.getId(),
                null,
                null,
                null,
                false
        );
        // optionally send email notifications for meeting created
        if (workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEETING_CREATED", true)) {
            for (MeetingParticipant p : participants) {
                try {
                    emailService.sendEmail(
                            p.getUser().getBoardEmail(),
                            "New meeting: " + meeting.getTitle(),
                            "A new meeting '" + meeting.getTitle() + "' has been scheduled on " + meeting.getMeetingDateTime()
                    );
                } catch (Exception ex) {
                    // log and continue
                }
            }
        }
    }

    @Transactional
    public void notifyMeetingReminder(Meeting meeting, List<MeetingParticipant> participants) {
        createForRecipients(
                participants.stream().map(MeetingParticipant::getUser).toList(),
                meeting.getCreatedBy(),
                "Upcoming meeting reminder",
                "Reminder: " + meeting.getTitle() + " will take place on " + meeting.getMeetingDateTime() + ".",
                "MEETING_REMINDER",
                meeting.getId(),
                null,
                null,
                null,
                false
        );

        if (workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEETING_REMINDER", true)) {
            for (MeetingParticipant p : participants) {
                try {
                    emailService.sendEmail(
                            p.getUser().getBoardEmail(),
                            "Meeting reminder: " + meeting.getTitle(),
                            "Reminder: '" + meeting.getTitle() + "' will take place on " + meeting.getMeetingDateTime()
                    );
                } catch (Exception ex) {
                    // ignore individual email failures
                }
            }
        }
    }

    @Transactional
    public void notifyPaperCreated(Paper paper, List<MeetingParticipant> participants, User createdBy) {
        createForRecipients(
                participants.stream().map(MeetingParticipant::getUser).toList(),
                createdBy,
                "New paper created",
                paper.getTitle() + " is now available for review.",
                "PAPER_CREATED",
                paper.getMeeting().getId(),
                paper.getId(),
                null,
                null,
                false
        );
    }

    @Transactional
    public void notifyDocumentUploaded(PaperAttachment attachment, List<MeetingParticipant> participants, User createdBy) {
        createForRecipients(
                participants.stream().map(MeetingParticipant::getUser).toList(),
                createdBy,
                "Document uploaded",
                attachment.getFileName() + " has been uploaded.",
                "DOCUMENT_UPLOADED",
                attachment.getPaper().getMeeting().getId(),
                attachment.getPaper().getId(),
                null,
                attachment.getId(),
                false
        );
    }

    public void notifyApproval(User user, Paper paper, String approvalStatus) {
        createForRecipient(
                user,
                null,
                "Paper approval recorded",
                "Your approval action for paper '" + paper.getTitle() + "' was recorded as: " + approvalStatus,
                "APPROVAL_RECORDED",
                paper.getMeeting().getId(),
                paper.getId(),
                null,
                null,
                false
        );

        if (!workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_APPROVES_PAPER", false)) {
            return;
        }

        emailService.sendEmail(
                user.getBoardEmail(),
                "Paper Approval Recorded",
                "Your approval action for paper '" + paper.getTitle() + "' was recorded as: " + approvalStatus
        );
    }

    public void notifyCommentShared(User recipient, String sharedByUsername) {
        notifyCommentShared(recipient, sharedByUsername, null, null);
    }

    public void notifyCommentShared(User recipient, String sharedByUsername, Long paperId, Long commentId) {
        createForRecipient(
                recipient,
                null,
                "Comment shared",
                "A comment has been shared with you by " + sharedByUsername + ".",
                "COMMENT_SHARED",
                null,
                paperId,
                commentId,
                null,
                false
        );

        if (!workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_COMMENT", false)) {
            return;
        }

        emailService.sendEmail(
                recipient.getBoardEmail(),
                "A comment was shared with you",
                "A comment has been shared with you by " + sharedByUsername
        );
    }

    public void notifyAnnotatedPaperShared(User recipient, String paperTitle, String sharedByUsername) {
        notifyAnnotatedPaperShared(recipient, paperTitle, sharedByUsername, null);
    }

    public void notifyAnnotatedPaperShared(User recipient, String paperTitle, String sharedByUsername, Long paperId) {
        createForRecipient(
                recipient,
                null,
                "Paper shared",
                "Paper '" + paperTitle + "' has been shared with you by " + sharedByUsername + ".",
                "PAPER_SHARED",
                null,
                paperId,
                null,
                null,
                false
        );

        if (!workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_ANNOTATED_PAPER", false)) {
            return;
        }

        emailService.sendEmail(
                recipient.getBoardEmail(),
                "An annotated paper was shared with you",
                "Paper '" + paperTitle + "' has been shared with you by " + sharedByUsername
        );
    }

    private void createForRecipients(
            List<User> recipients,
            User createdBy,
            String title,
            String message,
            String type,
            Long meetingId,
            Long paperId,
            Long commentId,
            Long attachmentId,
            boolean announcement
    ) {
        Set<Long> seen = new HashSet<>();
        List<BoardNotification> notifications = recipients.stream()
                .filter(user -> user != null && user.getStatus() == UserStatus.ACTIVE)
                .filter(user -> seen.add(user.getId()))
                .map(user -> buildNotification(
                        user,
                        createdBy,
                        title,
                        message,
                        type,
                        meetingId,
                        paperId,
                        commentId,
                        attachmentId,
                        announcement
                ))
                .toList();

        notificationRepository.saveAll(notifications);
    }

    private void createForRecipient(
            User recipient,
            User createdBy,
            String title,
            String message,
            String type,
            Long meetingId,
            Long paperId,
            Long commentId,
            Long attachmentId,
            boolean announcement
    ) {
        if (recipient == null || recipient.getStatus() != UserStatus.ACTIVE) {
            return;
        }

        notificationRepository.save(buildNotification(
                recipient,
                createdBy,
                title,
                message,
                type,
                meetingId,
                paperId,
                commentId,
                attachmentId,
                announcement
        ));
    }

    private BoardNotification buildNotification(
            User recipient,
            User createdBy,
            String title,
            String message,
            String type,
            Long meetingId,
            Long paperId,
            Long commentId,
            Long attachmentId,
            boolean announcement
    ) {
        return BoardNotification.builder()
                .recipient(recipient)
                .createdBy(createdBy)
                .title(title)
                .message(message)
                .type(type)
                .relatedMeetingId(meetingId)
                .relatedPaperId(paperId)
                .relatedCommentId(commentId)
                .relatedAttachmentId(attachmentId)
                .announcement(announcement)
                .read(false)
                .build();
    }

    private NotificationResponse map(BoardNotification notification, Long currentUserId) {
        List<NotificationReaction> reactions = reactionRepository.findByNotificationId(notification.getId());
        Map<String, Long> reactionCounts = reactions.stream()
                .collect(Collectors.groupingBy(NotificationReaction::getReactionType, Collectors.counting()));
        String currentReaction = reactions.stream()
                .filter(reaction -> reaction.getUser().getId().equals(currentUserId))
                .map(NotificationReaction::getReactionType)
                .findFirst()
                .orElse(null);
        List<NotificationResponse.Reply> replies = replyRepository
                .findByNotificationIdOrderByCreatedAtAsc(notification.getId())
                .stream()
                .map(reply -> NotificationResponse.Reply.builder()
                        .id(reply.getId())
                        .userId(reply.getUser().getId())
                        .userName(senderName(reply.getUser()))
                        .profilePictureUrl(reply.getUser().getProfilePictureUrl())
                        .message(reply.getMessage())
                        .createdAt(reply.getCreatedAt())
                        .build())
                .toList();

        return NotificationResponse.builder()
                .id(notification.getId())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .type(notification.getType())
                .read(notification.isRead())
                .announcement(notification.isAnnouncement())
                .createdByUserId(notification.getCreatedBy() == null ? null : notification.getCreatedBy().getId())
                .createdByName(senderName(notification.getCreatedBy()))
                .createdByProfilePictureUrl(notification.getCreatedBy() == null ? null : notification.getCreatedBy().getProfilePictureUrl())
                .relatedMeetingId(notification.getRelatedMeetingId())
                .relatedPaperId(notification.getRelatedPaperId())
                .relatedCommentId(notification.getRelatedCommentId())
                .relatedAttachmentId(notification.getRelatedAttachmentId())
                .replies(replies)
                .reactionCounts(reactionCounts)
                .currentReaction(currentReaction)
                .createdAt(notification.getCreatedAt())
                .build();
    }

    private BoardNotification findNotification(Long notificationId) {
        return notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
    }

    private User findUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private String clean(String value, String fallback) {
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return value.trim();
    }

    private String senderName(User user) {
        if (user == null) {
            return "System";
        }
        if (user.getDisplayName() != null && !user.getDisplayName().trim().isEmpty()) {
            return user.getDisplayName().trim();
        }
        return (user.getFirstName() + " " + user.getLastName()).trim();
    }
}

