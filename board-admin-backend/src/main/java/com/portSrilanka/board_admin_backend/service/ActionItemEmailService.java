package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.MeetingActionItem;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class ActionItemEmailService {
    private final EmailService emailService;

    @Async
    public void sendAssignmentEmail(MeetingActionItem item) {
        String email = item.getAssignee().getBoardEmail();
        if (email == null || email.isBlank()) {
            log.warn("Action item {} assignee has no board email", item.getId());
            return;
        }

        String dueDate = item.getDueDate() == null ? "No due date" : item.getDueDate().toString();
        String details = item.getDescription() == null ? "No additional details" : item.getDescription();
        String body = "Hello " + item.getAssignee().getFirstName() + ",\n\n"
                + "A new action has been assigned to you.\n\n"
                + "Meeting: " + item.getMeeting().getTitle() + "\n"
                + "Action: " + item.getTitle() + "\n"
                + "Details: " + details + "\n"
                + "Due date: " + dueDate + "\n"
                + "Assigned by: " + item.getCreatedBy().getUsername() + "\n\n"
                + "Please sign in to BoardPAC to view and update this action.";
        try {
            emailService.sendEmail(email, "New BoardPAC action assigned: " + item.getTitle(), body);
        } catch (RuntimeException exception) {
            // The saved action must remain valid even if the mail server is unavailable.
            log.error("Could not send assignment email for action item {}", item.getId(), exception);
        }
    }
}
