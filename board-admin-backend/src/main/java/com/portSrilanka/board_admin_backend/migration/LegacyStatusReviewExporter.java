package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

/** Exports legacy workflow code distributions without assigning unverified meanings. */
public final class LegacyStatusReviewExporter {
    private LegacyStatusReviewExporter() {}

    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        Path output = Path.of(System.getenv().getOrDefault("MIGRATION_STATUS_REVIEW", "target/legacy-status-review.csv"))
                .toAbsolutePath().normalize();
        if (Files.exists(output)) throw new IllegalArgumentException("Review file already exists: " + output);
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        StringBuilder csv = new StringBuilder("source_area,legacy_field,legacy_code,row_count,current_handling,approved_meaning,approved_new_status,review_notes\r\n");
        int groups = 0;
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            groups += append(source, csv, "Meetings", "Status", "DRAFT",
                    "SELECT \"Status\"::text,count(*) FROM legacy_boardpac.\"dbo__Meetings\" GROUP BY 1 ORDER BY 1");
            groups += append(source, csv, "Papers", "PaperStatus", "READ_ONLY_HISTORY",
                    "SELECT \"PaperStatus\"::text,count(*) FROM legacy_boardpac.\"dbo__Papers\" GROUP BY 1 ORDER BY 1");
            groups += append(source, csv, "MeetingPresences", "IsPresent,IsAttending", "PENDING",
                    "SELECT COALESCE(\"IsPresent\"::text,'NULL') || '/' || COALESCE(\"IsAttending\"::text,'NULL'),count(*) FROM legacy_boardpac.\"dbo__MeetingPresences\" GROUP BY 1 ORDER BY 1");
            groups += append(target, csv, "PaperDecisionViews", "DecisionStatus", "READ_ONLY_HISTORY",
                    "SELECT decision_status::text,count(*) FROM legacy_paper_decisions GROUP BY 1 ORDER BY 1");
            groups += append(target, csv, "PaperDecisionViews", "DSApprovalStatus", "READ_ONLY_HISTORY",
                    "SELECT ds_approval_status::text,count(*) FROM legacy_paper_decisions GROUP BY 1 ORDER BY 1");
            groups += append(target, csv, "PaperDecisionViews", "NotificationStatus", "READ_ONLY_HISTORY",
                    "SELECT notification_status::text,count(*) FROM legacy_paper_decisions GROUP BY 1 ORDER BY 1");
            groups += append(target, csv, "PaperDecisionViews", "IsAllowed", "READ_ONLY_HISTORY",
                    "SELECT is_allowed::text,count(*) FROM legacy_paper_decisions GROUP BY 1 ORDER BY 1");
        }
        Files.createDirectories(output.getParent());
        Files.writeString(output, csv.toString(), StandardCharsets.UTF_8, java.nio.file.StandardOpenOption.CREATE_NEW);
        System.out.println("Exported " + groups + " legacy workflow code groups to " + output);
    }

    private static int append(Connection db, StringBuilder csv, String area, String field, String handling, String query) throws Exception {
        int groups = 0;
        try (Statement statement = db.createStatement(); ResultSet rows = statement.executeQuery(query)) {
            while (rows.next()) {
                csv.append(quoted(area)).append(',').append(quoted(field)).append(',')
                        .append(quoted(rows.getString(1) == null ? "NULL" : rows.getString(1))).append(',')
                        .append(rows.getLong(2)).append(',').append(quoted(handling)).append(",,,\r\n");
                groups++;
            }
        }
        return groups;
    }

    private static String quoted(String value) { return '"' + value.replace("\"", "\"\"") + '"'; }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
