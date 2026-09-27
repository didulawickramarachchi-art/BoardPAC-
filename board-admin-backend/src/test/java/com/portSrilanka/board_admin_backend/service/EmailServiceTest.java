package com.portSrilanka.board_admin_backend.service;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Properties;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EmailServiceTest {

    @Test
    void sendsMultipartPlainTextAndHtmlMessage() throws Exception {
        JavaMailSender sender = mock(JavaMailSender.class);
        MimeMessage message = new MimeMessage(Session.getInstance(new Properties()));
        when(sender.createMimeMessage()).thenReturn(message);
        EmailService service = new EmailService(sender);
        ReflectionTestUtils.setField(service, "from", "boardpac@example.com");
        ReflectionTestUtils.setField(service, "appIconUrl", "https://example.com/logo.png");

        service.sendEmail("member@example.com", "Meeting created", "A meeting was created.");

        verify(sender).send(any(MimeMessage.class));
        message.saveChanges();
        assertTrue(message.isMimeType("multipart/*"));
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        message.writeTo(output);
        String renderedMessage = output.toString(StandardCharsets.UTF_8);
        assertTrue(renderedMessage.contains("BoardPAC logo"));
        assertTrue(renderedMessage.contains("MEETING UPDATE"));
    }
}
