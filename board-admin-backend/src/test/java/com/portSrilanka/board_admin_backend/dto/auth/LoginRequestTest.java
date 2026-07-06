package com.portSrilanka.board_admin_backend.dto.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LoginRequestTest {

    @Test
    void shouldDeserializeLoginRequestFromJson() throws Exception {
        ObjectMapper objectMapper = new ObjectMapper();

        LoginRequest request = objectMapper.readValue(
                "{\"username\":\"admin\",\"password\":\"123456\"}",
                LoginRequest.class
        );

        assertThat(request.getUsername()).isEqualTo("admin");
        assertThat(request.getPassword()).isEqualTo("123456");
    }
}
