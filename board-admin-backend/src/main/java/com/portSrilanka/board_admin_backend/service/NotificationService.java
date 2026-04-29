package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.Paper;
import com.portSrilanka.board_admin_backend.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final EmailService emailService;
    private final WorkflowSettingService workflowSettingService;

    public void notifyApproval(User user, Paper paper, String approvalStatus) {
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
        if (!workflowSettingService.isEnabled("SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_ANNOTATED_PAPER", false)) {
            return;
        }

        emailService.sendEmail(
                recipient.getBoardEmail(),
                "An annotated paper was shared with you",
                "Paper '" + paperTitle + "' has been shared with you by " + sharedByUsername
        );
    }
}