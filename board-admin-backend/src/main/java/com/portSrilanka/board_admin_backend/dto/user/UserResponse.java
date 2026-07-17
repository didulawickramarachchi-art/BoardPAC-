package com.portSrilanka.board_admin_backend.dto.user;

import com.portSrilanka.board_admin_backend.enums.UserStatus;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserResponse {
    private Long id;
    private String username;
    private String firstName;
    private String lastName;
    private String displayName;
    private String boardEmail;
    private String mobileNumber;
    private String jobTitle;
    private String profilePictureUrl;
    private String role;
    private UserStatus status;
}
