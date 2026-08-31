package com.portSrilanka.board_admin_backend.dto.meeting;
import lombok.Data;
import java.time.LocalDate;
@Data public class ActionItemRequest { private String title; private String description; private Long assigneeUserId; private LocalDate dueDate; }
