package com.portSrilanka.board_admin_backend.dto.meeting;
import com.portSrilanka.board_admin_backend.enums.ActionItemStatus;
import lombok.Builder; import lombok.Data;
import java.time.*;
@Data @Builder public class ActionItemResponse { private Long id; private Long meetingId; private String title; private String description; private Long assigneeUserId; private String assigneeUsername; private String createdByUsername; private LocalDate dueDate; private ActionItemStatus status; private String completionNote; private boolean editableByCurrentUser; private LocalDateTime createdAt; private LocalDateTime updatedAt; }
