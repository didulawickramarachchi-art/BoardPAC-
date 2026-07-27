package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.dto.auth.LoginRequest;
import com.portSrilanka.board_admin_backend.dto.auth.LoginResponse;
import com.portSrilanka.board_admin_backend.service.AuthService;
import com.portSrilanka.board_admin_backend.service.PasswordResetService;
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
    private PasswordResetService passwordResetService =
            org.mockito.Mockito.mock(PasswordResetService.class);

    private void setUpMockMvc() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders
                .standaloneSetup(new AuthController(authService, passwordResetService))
                .setValidator(validator)
                .build();
    }

    @Test
    void loginShouldAcceptFormUrlEncodedCredentials() throws Exception {
        setUpMockMvc();

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

    @Test
    void passwordResetRequestShouldSendEmailWithoutDisclosingAccount() throws Exception {
        setUpMockMvc();

        mockMvc.perform(post("/api/auth/password-reset/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"member@example.com\"}"))
                .andExpect(status().isOk());

        verify(passwordResetService).sendResetEmail("member@example.com");
    }

    @Test
    void resetPasswordShouldAcceptTokenAndStrongPassword() throws Exception {
        setUpMockMvc();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"secure-token\","
                                + "\"newPassword\":\"NewPassword1\"}"))
                .andExpect(status().isOk());

        verify(passwordResetService).resetPassword(any());
    }
}
