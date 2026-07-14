package com.portSrilanka.board_admin_backend.dto.comment;

import com.portSrilanka.board_admin_backend.enums.ReactionType;
import lombok.Data;

@Data
public class ReactionRequest {
    private ReactionType reactionType;
}
