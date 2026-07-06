package com.portSrilanka.board_admin_backend.security;

import com.portSrilanka.board_admin_backend.dto.access.AccessValidationResponse;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.enums.AccessChannel;
import com.portSrilanka.board_admin_backend.enums.BoardType;
import org.springframework.stereotype.Service;

@Service
public class ChannelAccessService {

    public AccessValidationResponse validate(User user, AccessChannel requestedChannel) {
        boolean allowed = false;
        String reason = "Access denied for this channel";

        if (user.getBoardType() == BoardType.MEMBER) {
            allowed = requestedChannel == AccessChannel.DEVICE;
            reason = allowed ? "Allowed" : "Members can access only via device";
        } else if (user.getBoardType() == BoardType.ORGANIZER) {
            allowed = true;
            reason = "Allowed";
        } else if (user.getBoardType() == BoardType.SUPPORT_TEAM) {
            allowed = requestedChannel == AccessChannel.WEB;
            reason = allowed ? "Allowed" : "Support team can access only via web";
        }

        return AccessValidationResponse.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .requestedChannel(requestedChannel.name())
                .allowed(allowed)
                .reason(reason)
                .build();
    }
}
