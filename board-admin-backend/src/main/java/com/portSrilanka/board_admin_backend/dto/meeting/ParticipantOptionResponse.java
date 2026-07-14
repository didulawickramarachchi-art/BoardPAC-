package com.portSrilanka.board_admin_backend.dto.meeting;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ParticipantOptionResponse {
    private Long id;
    private String username;
    private String firstName;
    private String lastName;
    private String displayName;
    private boolean participant;
    private boolean eligible;
}
