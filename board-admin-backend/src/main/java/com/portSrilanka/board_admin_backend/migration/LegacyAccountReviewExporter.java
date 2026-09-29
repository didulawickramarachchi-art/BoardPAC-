package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

/** Read-only account review for an isolated migration rehearsal. CSV contains personal data. */
public final class LegacyAccountReviewExporter {
    private LegacyAccountReviewExporter() {}

    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL");
        String targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        Path output = Path.of(System.getenv().getOrDefault("MIGRATION_ACCOUNT_REVIEW", "target/legacy-account-review.csv"))
                .toAbsolutePath().normalize();
        if (Files.exists(output)) throw new IllegalArgumentException("Review file already exists: " + output);

        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Map<Long, String> sourceEmails = new HashMap<>();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Statement statement = source.createStatement();
             ResultSet rows = statement.executeQuery("SELECT \"CustomUserId\",\"BoardEmail\" FROM legacy_boardpac.\"dbo__Users\"")) {
            while (rows.next()) {
                byte[] raw = rows.getBytes(2);
                sourceEmails.put(rows.getLong(1), raw == null ? "" : new String(raw, StandardCharsets.UTF_16LE).trim());
            }
        }

        String sql = "SELECT u.id,u.username,u.board_email,u.office_email,u.status,u.access_profile," +
                " COALESCE(string_agg(DISTINCT r.name, ';' ORDER BY r.name),'')," +
                " COALESCE((SELECT string_agg(a.subcategory_id::text || ':' || a.assigned_role, ';' ORDER BY a.subcategory_id)" +
                " FROM user_subcategory_access a WHERE a.user_id=u.id),'')" +
                " FROM users u JOIN legacy_import_map m ON m.entity='users' AND m.app_id=u.id" +
                " LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id" +
                " GROUP BY u.id ORDER BY u.id";
        StringBuilder csv = new StringBuilder("legacy_user_id,username,source_board_email,app_board_email,office_email,role,access_profile,current_grants,status,email_conflict,no_explicit_grant,approved_unique_email,approved_grants,approved_for_activation,review_notes\r\n");
        int count = 0, conflicts = 0, noGrants = 0;
        try (Connection target = DriverManager.getConnection(targetUrl, user, password);
             PreparedStatement statement = target.prepareStatement(sql);
             ResultSet rows = statement.executeQuery()) {
            while (rows.next()) {
                long id = rows.getLong(1);
                String original = sourceEmails.get(id);
                if (original == null) throw new IllegalStateException("Missing staged user " + id);
                String appEmail = rows.getString(3);
                String grants = rows.getString(8);
                boolean conflict = appEmail.endsWith("@migration.invalid");
                boolean noGrant = grants.isEmpty();
                if (!"DEACTIVATED".equals(rows.getString(5)))
                    throw new IllegalStateException("Imported user is already active: " + id);
                csv.append(id);
                for (String value : new String[] {rows.getString(2), original, appEmail, rows.getString(4),
                        rows.getString(7), rows.getString(6), grants, rows.getString(5),
                        conflict ? "YES" : "NO", noGrant ? "YES" : "NO", "", "", "NO", ""}) {
                    csv.append(',').append(csv(value));
                }
                csv.append("\r\n");
                count++;
                if (conflict) conflicts++;
                if (noGrant) noGrants++;
            }
        }
        if (count != sourceEmails.size()) throw new IllegalStateException("Source/app user counts differ");
        Files.createDirectories(output.getParent());
        Files.writeString(output, csv.toString(), StandardCharsets.UTF_8, java.nio.file.StandardOpenOption.CREATE_NEW);
        System.out.println("Account review exported: " + count + " disabled users, " + conflicts +
                " email conflicts, " + noGrants + " users without explicit grants. File: " + output);
    }

    private static String csv(String value) {
        if (value == null) value = "";
        // Prevent spreadsheet formula execution when the review CSV is opened in Excel.
        if (!value.isEmpty() && "=+-@".indexOf(value.charAt(0)) >= 0) value = "'" + value;
        return '"' + value.replace("\"", "\"\"") + '"';
    }

    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
