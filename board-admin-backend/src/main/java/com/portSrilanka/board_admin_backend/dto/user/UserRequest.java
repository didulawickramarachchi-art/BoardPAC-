package com.portSrilanka.board_admin_backend.dto.user;

import com.portSrilanka.board_admin_backend.enums.BoardType;
import com.portSrilanka.board_admin_backend.enums.AccessProfile;
import lombok.Data;

@Data
public class UserRequest {
    private String salutation;
    private String firstName;
    private String lastName;
    private String displayName;
    private String boardEmail;
    private String officeEmail;
    private String officeNumber;
    private String mobileNumber;
    private String jobTitle;
    private String profilePictureUrl;
    private boolean twoStepEnabled;
    private String role;
    private BoardType boardType;
    private AccessProfile accessProfile;
}
