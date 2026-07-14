package com.portSrilanka.board_admin_backend.enums;

public enum SystemRole {
    ADMIN,
    SECRETARY,
    MEMBER,
    SUPER_ADMIN,
    BOARD_ADMIN,
    BOARD_SECRETARY,
    SUPPORT_TEAM;

    public String authorityName() {
        return switch (this) {
            case SUPER_ADMIN, BOARD_ADMIN, SUPPORT_TEAM -> ADMIN.name();
            case BOARD_SECRETARY -> SECRETARY.name();
            default -> name();
        };
    }
}
