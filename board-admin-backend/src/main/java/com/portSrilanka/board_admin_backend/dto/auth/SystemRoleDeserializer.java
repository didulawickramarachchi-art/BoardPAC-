package com.portSrilanka.board_admin_backend.dto.auth;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.portSrilanka.board_admin_backend.enums.SystemRole;
import java.io.IOException;

public class SystemRoleDeserializer extends JsonDeserializer<SystemRole> {

    @Override
    public SystemRole deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String value = p.getValueAsString();
        
        if (value == null || value.trim().isEmpty()) {
            return SystemRole.MEMBER; // Default role
        }
        
        try {
            return SystemRole.valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            // If invalid role is provided, default to MEMBER
            return SystemRole.MEMBER;
        }
    }
}
