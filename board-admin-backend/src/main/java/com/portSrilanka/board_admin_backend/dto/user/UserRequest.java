package com.portSrilanka.board_admin_backend.dto.user;

import com.portSrilanka.board_admin_backend.enums.BoardType;
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
    private BoardType boardType;
    private boolean twoStepEnabled;
}