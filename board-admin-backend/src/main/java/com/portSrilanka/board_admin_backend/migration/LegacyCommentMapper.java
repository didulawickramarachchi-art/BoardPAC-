package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Base64;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.flywaydb.core.Flyway;

/** Imports decrypted comments and notes, keeping uncertain approvals read-only. */
public final class LegacyCommentMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Map<String, Map<Long, String>> text = readText(Path.of(required("MIGRATION_ACTIVITY_TEXT")));
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            try {
                for (String table : new String[]{"comments", "comment_shares", "meeting_notes", "legacy_archive_comments", "legacy_approval_comments"})
                    requireEmpty(target, table);
                Set<Long> imported = importComments(source, target, text.get("comment"));
                importShares(source, target, imported);
                importNotes(source, target, text.get("meeting_note"));
                importApprovalComments(source, target, text.get("approval_comment"));
                for (String table : new String[]{"comments", "comment_shares", "meeting_notes"}) resetSequence(target, table);
                target.commit();
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }

    private static Set<Long> importComments(Connection source, Connection target, Map<Long, String> text) throws SQLException {
        Set<Long> imported = new HashSet<>();
        int archived = 0;
        String query = "SELECT \"CommentId\",\"RefId\",\"RefType\",\"CreatedBy\",\"CreatedDate\" FROM legacy_boardpac.\"dbo__Comments\" ORDER BY \"CommentId\"";
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement app = target.prepareStatement("INSERT INTO comments(id,meeting_id,paper_id,created_by,comment_text,annotated,created_at) VALUES (?,?,?,?,?,false,?)");
             PreparedStatement archive = target.prepareStatement("INSERT INTO legacy_archive_comments(comment_id,paper_id,created_by,comment_text,created_at) VALUES (?,?,?,?,?)");
             PreparedStatement paper = target.prepareStatement("SELECT 1 FROM papers WHERE id=?")) {
            while (row.next()) {
                long id = row.getLong(1), ref = row.getLong(2), author = row.getLong(4);
                int type = row.getInt(3);
                String body = text.get(id);
                if (body == null || body.isBlank()) throw new SQLException("Missing decrypted comment " + id);
                if (type == 0) {
                    paper.setLong(1, ref);
                    try (ResultSet found = paper.executeQuery()) {
                        if (!found.next()) {
                            archive.setLong(1, id); archive.setLong(2, ref); archive.setLong(3, author);
                            archive.setString(4, body); archive.setTimestamp(5, row.getTimestamp(5)); archive.executeUpdate();
                            archived++; continue;
                        }
                    }
                } else if (type != 1) throw new SQLException("Unknown comment reference type " + type);
                app.setLong(1, id);
                if (type == 1) app.setLong(2, ref); else app.setNull(2, java.sql.Types.BIGINT);
                if (type == 0) app.setLong(3, ref); else app.setNull(3, java.sql.Types.BIGINT);
                app.setLong(4, author);
                app.setString(5, limit(body, 4000));
                app.setTimestamp(6, row.getTimestamp(5));
                app.executeUpdate();
                if (body.length() > 4000) issue(target, "comments", id, "Decrypted text exceeds app limit; full text remains in staging.");
                imported.add(id);
            }
        }
        if (imported.size() != 21 || archived != 4) throw new SQLException("Unexpected comment count");
        System.out.println("comments -> " + imported.size() + "; archived comments -> " + archived);
        return imported;
    }

    private static void importShares(Connection source, Connection target, Set<Long> imported) throws SQLException {
        int linked = 0, archived = 0;
        String query = "SELECT a.\"CommentId\",a.\"CustomUserId\",c.\"CreatedBy\" FROM legacy_boardpac.\"dbo__CommentAccesses\" a JOIN legacy_boardpac.\"dbo__Comments\" c ON c.\"CommentId\"=a.\"CommentId\"";
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement("INSERT INTO comment_shares(comment_id,shared_by,shared_to) VALUES (?,?,?)")) {
            while (row.next()) {
                if (!imported.contains(row.getLong(1))) { archived++; continue; }
                write.setLong(1, row.getLong(1)); write.setLong(2, row.getLong(3)); write.setLong(3, row.getLong(2));
                write.executeUpdate(); linked++;
            }
        }
        if (linked + archived != 163 || archived != 29) throw new SQLException("Unexpected comment access count");
        issue(target, "comment_shares", 0, archived + " access rows for archived comments remain in staging.");
        System.out.println("comment_shares -> " + linked + "; archived access rows -> " + archived);
    }

    private static void importNotes(Connection source, Connection target, Map<Long, String> text) throws SQLException {
        int count = 0;
        String query = "SELECT \"MeetingId\",\"CustomUserId\" FROM legacy_boardpac.\"dbo__MeetingPresences\" WHERE \"MeetingNote\" IS NOT NULL AND octet_length(\"MeetingNote\")>0";
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement("INSERT INTO meeting_notes(meeting_id,user_id,note_text) VALUES (?,?,?)")) {
            while (row.next()) {
                long meeting = row.getLong(1), user = row.getLong(2);
                String body = text.get(meeting * 1_000_000L + user);
                if (body == null || body.isBlank()) throw new SQLException("Missing decrypted meeting note");
                write.setLong(1, meeting); write.setLong(2, user); write.setString(3, limit(body, 5000));
                write.executeUpdate();
                if (body.length() > 5000) issue(target, "meeting_notes", meeting * 1_000_000L + user, "Full note remains in staging; app value truncated.");
                count++;
            }
        }
        if (count != 5) throw new SQLException("Unexpected meeting note count");
        System.out.println("meeting_notes -> " + count);
    }

    private static void importApprovalComments(Connection source, Connection target, Map<Long, String> text) throws SQLException {
        int count = 0;
        String query = "SELECT \"PaperId\",\"CustomUserId\" FROM legacy_boardpac.\"dbo__PaperDecisionViews\" WHERE \"ApprovalComment\" IS NOT NULL AND octet_length(\"ApprovalComment\")>0";
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement("INSERT INTO legacy_approval_comments(paper_id,user_id,comment_text) VALUES (?,?,?)")) {
            while (row.next()) {
                long paper = row.getLong(1), user = row.getLong(2);
                String body = text.get(paper * 1_000_000L + user);
                if (body == null || body.isBlank()) throw new SQLException("Missing decrypted approval comment");
                write.setLong(1, paper); write.setLong(2, user); write.setString(3, body); write.executeUpdate();
                count++;
            }
        }
        if (count != 23) throw new SQLException("Unexpected approval comment count");
        System.out.println("legacy_approval_comments -> " + count + " (read-only; decision statuses remain staged)");
    }

    private static Map<String, Map<Long, String>> readText(Path path) throws Exception {
        Map<String, Map<Long, String>> result = new HashMap<>();
        for (String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
            String[] fields = line.split("\\t", -1);
            if (fields.length != 3 || !Set.of("comment", "meeting_note", "approval_comment").contains(fields[0]))
                throw new IllegalArgumentException("Invalid activity text row");
            Map<Long, String> group = result.computeIfAbsent(fields[0], key -> new HashMap<>());
            long id = Long.parseLong(fields[1]);
            if (group.put(id, new String(Base64.getDecoder().decode(fields[2]), StandardCharsets.UTF_8)) != null)
                throw new IllegalArgumentException("Duplicate activity text ID");
        }
        if (result.getOrDefault("comment", Map.of()).size() != 25
                || result.getOrDefault("meeting_note", Map.of()).size() != 5
                || result.getOrDefault("approval_comment", Map.of()).size() != 23)
            throw new IllegalArgumentException("Unexpected activity text counts");
        return result;
    }
    private static void requireEmpty(Connection db, String table) throws SQLException {
        try (Statement s = db.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM " + table)) {
            r.next(); if (r.getLong(1) != 0) throw new SQLException("Destination " + table + " is not empty");
        }
    }
    private static void resetSequence(Connection db, String table) throws SQLException {
        try (Statement s = db.createStatement()) {
            s.execute("SELECT setval(pg_get_serial_sequence('" + table + "','id'), (SELECT max(id) FROM " + table + "))");
        }
    }
    private static void issue(Connection db, String entity, long id, String message) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_issues VALUES (?,?,?)")) {
            p.setString(1, entity); p.setLong(2, id); p.setString(3, message); p.executeUpdate();
        }
    }
    private static String limit(String text, int max) { return text.length() <= max ? text : text.substring(0, max); }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
