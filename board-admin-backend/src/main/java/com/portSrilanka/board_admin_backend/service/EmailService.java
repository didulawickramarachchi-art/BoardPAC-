package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${APP_MAIL_FROM}")
    private String from;

    @Value("${APP_ICON_URL:https://github.com/user-attachments/assets/027fe728-69cb-4fe5-9d7b-fb75351ef399}")
    private String appIconUrl;

    public void sendEmail(String to, String subject, String body) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            // Multipart mode is required when setting both plain-text and HTML
            // alternatives with setText(plainText, htmlText).
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(toPlainText(body), buildHtml(subject, body));
            mailSender.send(message);
            log.info("Email sent successfully to {}", to);
        } catch (MailException | MessagingException ex) {
            log.error("Unable to send email to {}", to, ex);
            throw new BadRequestException("Unable to send verification email. Please check mail server configuration.");
        }
    }

    private String buildHtml(String subject, String body) {
        String safeSubject = escapeHtml(subject);
        EmailPresentation presentation = presentationFor(subject);
        String safeBody = formatBody(body);
        String safeIconUrl = escapeHtml(appIconUrl);
        return """
                <!doctype html><html><body style="margin:0;background:#edf2fa;font-family:Arial,sans-serif;color:#172033">
                <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background:#edf2fa;padding:32px 12px"><tr><td align="center">
                <table role="presentation" width="620" cellspacing="0" cellpadding="0" style="max-width:620px;width:100%%;background:#fff;border-radius:22px;overflow:hidden;border:1px solid #dce4f1;box-shadow:0 12px 35px rgba(8,30,75,.10)">
                <tr><td style="background:#10275d;padding:25px 32px;border-bottom:4px solid #ffb52e"><table role="presentation"><tr>
                <td><img src="%s" alt="BoardPAC logo" width="68" height="68" style="display:block;object-fit:contain"></td>
                <td style="padding-left:18px;color:#fff"><div style="font-size:23px;font-weight:700;letter-spacing:.2px">BoardPAC</div><div style="color:#ffbd42;font-size:11px;margin-top:5px;letter-spacing:1px;font-weight:700">BOARD MANAGEMENT SYSTEM</div></td>
                </tr></table></td></tr>
                <tr><td style="padding:34px 32px 12px"><span style="display:inline-block;background:#fff3d6;color:#8a5900;border-radius:999px;padding:7px 12px;font-size:11px;font-weight:700;letter-spacing:.7px">%s</span>
                <h1 style="font-size:24px;line-height:1.3;color:#071d4e;margin:18px 0 12px">%s</h1>
                <div style="font-size:15px;line-height:1.7;color:#34425f">%s</div></td></tr>
                <tr><td style="padding:14px 32px 32px"><table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background:#f5f8fd;border-left:4px solid #ffb52e;border-radius:10px"><tr><td style="padding:15px 17px;color:#50607c;font-size:13px;line-height:1.55">%s</td></tr></table></td></tr>
                <tr><td style="padding:19px 32px;background:#10275d;color:#aebbd8;font-size:12px;line-height:1.5"><strong style="color:#fff">BoardPAC</strong> · Sri Lanka Ports Authority<br>This is an automated notification. Please do not reply.</td></tr>
                </table></td></tr></table></body></html>
                """.formatted(
                safeIconUrl,
                escapeHtml(presentation.label()),
                safeSubject,
                safeBody,
                escapeHtml(presentation.guidance())
        );
    }

    private String formatBody(String body) {
        String normalized = toPlainText(body).replace("\r\n", "\n").replace("\r", "\n").trim();
        if (normalized.isEmpty()) return "";
        String[] paragraphs = normalized.split("\n{2,}");
        StringBuilder html = new StringBuilder();
        for (String paragraph : paragraphs) {
            if (!html.isEmpty()) html.append("<div style=\"height:12px\"></div>");
            html.append("<div>")
                    .append(escapeHtml(paragraph).replace("\n", "<br>"))
                    .append("</div>");
        }
        return html.toString();
    }

    private EmailPresentation presentationFor(String subject) {
        String value = subject == null ? "" : subject.toLowerCase();
        if (value.contains("password") || value.contains("verification")) {
            return new EmailPresentation("ACCOUNT SECURITY",
                    "For your security, never share verification codes or password links with anyone.");
        }
        if (value.contains("device")) {
            return new EmailPresentation("DEVICE ACCESS",
                    "Open BoardPAC Device Management to review device access and approval status.");
        }
        if (value.contains("meeting") || value.contains("circular")) {
            return new EmailPresentation("MEETING UPDATE",
                    "Open BoardPAC to view the agenda, papers, participants, and latest meeting information.");
        }
        if (value.contains("paper") || value.contains("attachment") || value.contains("document")) {
            return new EmailPresentation("DOCUMENT UPDATE",
                    "Open BoardPAC to securely review the document and complete any required action.");
        }
        if (value.contains("user") || value.contains("welcome")) {
            return new EmailPresentation("ACCOUNT UPDATE",
                    "Sign in to BoardPAC to complete your profile and access your assigned workspace.");
        }
        if (value.contains("action")) {
            return new EmailPresentation("ACTION ITEM",
                    "Open BoardPAC to review this action item and keep its progress up to date.");
        }
        return new EmailPresentation("BOARDPAC NOTIFICATION",
                "Open BoardPAC to review the latest information and available actions.");
    }

    private record EmailPresentation(String label, String guidance) {}

    private String toPlainText(String value) {
        return value == null ? "" : value;
    }

    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
