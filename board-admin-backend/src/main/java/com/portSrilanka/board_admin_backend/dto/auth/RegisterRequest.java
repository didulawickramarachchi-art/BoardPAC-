package com.portSrilanka.board_admin_backend.dto.auth;

import com.portSrilanka.board_admin_backend.enums.BoardType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank
    private String username;

    @NotBlank
    private String password;

    @NotBlank
    private String firstName;

    @NotBlank
    private String lastName;

    @Email
    @NotBlank
    private String boardEmail;

    private BoardType boardType;
}
