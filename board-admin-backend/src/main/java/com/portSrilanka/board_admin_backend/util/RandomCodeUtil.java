package com.portSrilanka.board_admin_backend.util;

import java.security.SecureRandom;

public final class RandomCodeUtil {

    private static final SecureRandom RANDOM = new SecureRandom();

    private RandomCodeUtil() {}

    public static String generateSixDigitCode() {
        int number = 100000 + RANDOM.nextInt(900000);
        return String.valueOf(number);
    }
}
