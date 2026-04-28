package com.portSrilanka.board_admin_backend.service;

import com.portSrilanka.board_admin_backend.entity.TwoFactorCode;
import com.portSrilanka.board_admin_backend.entity.User;
import com.portSrilanka.board_admin_backend.exception.BadRequestException;
import com.portSrilanka.board_admin_backend.repository.TwoFactorCodeRepository;
import com.portSrilanka.board_admin_backend.util.RandomCodeUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class TwoFactorService {

    private final TwoFactorCodeRepository twoFactorCodeRepository;
    private final EmailService emailService;

    @Value("${app.twofactor.code-expiration-minutes}")
    private long codeExpirationMinutes;

    public void generateAndSendCode(User user) {
        String code = RandomCodeUtil.generateSixDigitCode();

        TwoFactorCode twoFactorCode = TwoFactorCode.builder()
                .user(user)
                .code(code)
                .expiresAt(LocalDateTime.now().plusMinutes(codeExpirationMinutes))
                .used(false)
                .build();

        twoFactorCodeRepository.save(twoFactorCode);

        emailService.sendEmail(
                user.getBoardEmail(),
                "Board Admin Verification Code",
                "Your verification code is: " + code + "\n\nThis code will expire in " + codeExpirationMinutes + " minutes."
        );
    }

    public void verifyCode(User user, String code) {
        TwoFactorCode record = twoFactorCodeRepository
                .findTopByUserIdAndCodeAndUsedFalseOrderByCreatedAtDesc(user.getId(), code)
                .orElseThrow(() -> new BadRequestException("Invalid verification code"));

        if (record.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Verification code has expired");
        }

        record.setUsed(true);
        twoFactorCodeRepository.save(record);
    }
}