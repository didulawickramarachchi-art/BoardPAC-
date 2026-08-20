package com.portSrilanka.board_admin_backend.enums;

/**
 * Product access profiles described by the BoardPAC user manuals. A profile
 * refines a user's broad system role; it is intentionally separate from
 * BoardType, which controls the allowed access channel.
 */
public enum AccessProfile {
    BOARD_ADMINISTRATOR(SystemRole.ADMIN),
    SYSTEM_ADMINISTRATOR(SystemRole.ADMIN),
    BOARD_SECRETARY(SystemRole.SECRETARY),
    SECRETARY_ASSISTANT(SystemRole.SECRETARY),
    SECRETARY_UPLOAD_ONLY(SystemRole.SECRETARY),
    MEMBER(SystemRole.MEMBER),
    MEMBER_VIEW_ONLY(SystemRole.MEMBER),
    MEMBER_VIEW_COMMENTS(SystemRole.MEMBER);

    private final SystemRole systemRole;

    AccessProfile(SystemRole systemRole) {
        this.systemRole = systemRole;
    }

    public boolean supports(SystemRole role) {
        return systemRole == role;
    }

    public static AccessProfile defaultFor(SystemRole role) {
        return switch (role) {
            case ADMIN -> BOARD_ADMINISTRATOR;
            case SECRETARY -> BOARD_SECRETARY;
            case MEMBER -> MEMBER;
        };
    }
}
