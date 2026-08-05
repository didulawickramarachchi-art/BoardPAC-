package com.portSrilanka.board_admin_backend.dto.user;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TwoFactorSettingsRequest {
    private boolean enabled;
}
