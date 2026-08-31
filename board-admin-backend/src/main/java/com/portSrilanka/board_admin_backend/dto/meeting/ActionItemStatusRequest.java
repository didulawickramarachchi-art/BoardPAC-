package com.portSrilanka.board_admin_backend.dto.meeting;
import com.portSrilanka.board_admin_backend.enums.ActionItemStatus;
import lombok.Data;
@Data public class ActionItemStatusRequest { private ActionItemStatus status; private String completionNote; }
