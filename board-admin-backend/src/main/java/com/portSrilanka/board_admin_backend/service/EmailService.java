package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Async;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${APP_MAIL_FROM}")
    private String from;

    @Value("${APP_ICON_URL:https://boardpac.srilankaports.com/assets/images/logo.png}")
    private String appIconUrl;

    @Async
    public void sendEmail(String to, String subject, String body) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(toPlainText(body), buildHtml(subject, body));
            mailSender.send(message);
        } catch (MailException | MessagingException ex) {
            log.error("Unable to send email to {}", to, ex);
            throw new BadRequestException("Unable to send verification email. Please check mail server configuration.");
        }
    }

    private String buildHtml(String subject, String body) {
        String safeSubject = escapeHtml(subject);
        String safeBody = escapeHtml(body).replace("\r\n", "\n").replace("\r", "\n")
                .replaceAll("\n{2,}", "</p><p style=\"margin:0 0 16px\">")
                .replace("\n", "<br>");
        String safeIconUrl = escapeHtml(appIconUrl);
        return """
                <!doctype html><html><body style="margin:0;background:#f3f6fc;font-family:Arial,sans-serif;color:#172033">
                <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background:#f3f6fc;padding:28px 12px"><tr><td align="center">
                <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width:600px;width:100%%;background:#fff;border-radius:18px;overflow:hidden;border:1px solid #e1e6f0">
                <tr><td style="background:#12275b;padding:24px 30px"><table role="presentation"><tr>
                <td><img src="%s" alt="BoardPAC" width="58" height="58" style="display:block;border-radius:14px;background:#fff;object-fit:contain"></td>
                <td style="padding-left:16px;color:#fff"><div style="font-size:21px;font-weight:700">BoardPAC</div><div style="color:#ffb52e;font-size:12px;margin-top:4px;letter-spacing:.7px">SRI LANKA PORTS AUTHORITY</div></td>
                </tr></table></td></tr>
                <tr><td style="padding:32px 30px 22px"><h1 style="font-size:22px;line-height:1.3;color:#061b4e;margin:0 0 20px">%s</h1><p style="font-size:15px;line-height:1.65;margin:0 0 16px">%s</p></td></tr>
                <tr><td style="padding:18px 30px;background:#f8f9fc;border-top:1px solid #e1e6f0;color:#7d8cb2;font-size:12px;line-height:1.5">This is an automated BoardPAC notification. Please do not reply to this email.</td></tr>
                </table></td></tr></table></body></html>
                """.formatted(safeIconUrl, safeSubject, safeBody);
    }

    private String toPlainText(String value) {
        return value == null ? "" : value;
    }

    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
