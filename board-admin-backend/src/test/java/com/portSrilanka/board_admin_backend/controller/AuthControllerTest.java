package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.auth.LoginRequest;
import com.portSrilanka.board_admin_backend.dto.auth.LoginResponse;
import com.portSrilanka.board_admin_backend.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthControllerTest {

    private MockMvc mockMvc;

    private AuthService authService = org.mockito.Mockito.mock(AuthService.class);

    @Test
    void loginShouldAcceptFormUrlEncodedCredentials() throws Exception {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders.standaloneSetup(new AuthController(authService))
                .setValidator(validator)
                .build();

        org.mockito.Mockito.when(authService.login(org.mockito.ArgumentMatchers.any(LoginRequest.class)))
                .thenReturn(LoginResponse.builder().token("jwt-token").message("Login successful").build());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("username", "admin")
                        .param("password", "123456"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"));

        org.mockito.Mockito.verify(authService).login(org.mockito.ArgumentMatchers.any(LoginRequest.class));
    }
}
