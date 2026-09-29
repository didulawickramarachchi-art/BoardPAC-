package com.portSrilanka.board_admin_backend.migration;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;

/** Imports legacy participation and read timestamps without guessing workflow statuses. */
public final class LegacyActivityMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL");
        String targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            try {
                requireEmpty(target, "meeting_participants");
                requireEmpty(target, "paper_read_states");
                requireMap(target, "meetings", 158);
                requireMap(target, "papers", 4145);
                importParticipants(source, target);
                importReadStates(source, target);
                resetSequence(target, "meeting_participants");
                resetSequence(target, "paper_read_states");
                target.commit();
            } catch (Exception e) {
                target.rollback();
                throw e;
            }
        }
    }

    private static void importParticipants(Connection source, Connection target) throws SQLException {
        String query = "SELECT \"MeetingId\",\"CustomUserId\",\"IsPresent\",\"IsAttending\",\"AttendenceReason\",\"MeetingNote\" FROM legacy_boardpac.\"dbo__MeetingPresences\" ORDER BY \"MeetingId\",\"CustomUserId\"";
        String insert = "INSERT INTO meeting_participants(meeting_id,user_id,participant_status,status_reason) VALUES (?,?,'PENDING',?)";
        int count = 0;
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement(insert)) {
            while (row.next()) {
                long meeting = row.getLong(1), user = row.getLong(2);
                write.setLong(1, meeting);
                write.setLong(2, user);
                String reason = decode(row.getBytes(5));
                write.setString(3, reason == null ? null : limit(reason, 1000));
                write.executeUpdate();
                long sourceKey = meeting * 1_000_000L + user;
                issue(target, "meeting_participants", sourceKey,
                        "Legacy IsPresent=" + row.getInt(3) + ", IsAttending=" + row.getInt(4)
                        + "; imported PENDING until attendance mapping is confirmed.");
                byte[] note = row.getBytes(6);
                if (note != null && note.length > 0)
                    issue(target, "meeting_participants", sourceKey,
                            "Legacy meeting note remains in staging; encrypted text needs conversion.");
                count++;
            }
        }
        if (count != 2073) throw new SQLException("Unexpected legacy meeting presence count: " + count);
        System.out.println("meeting_participants -> " + count + " (PENDING; legacy attendance flags audited)");
    }

    private static void importReadStates(Connection source, Connection target) throws SQLException {
        // Source and target are separate databases, so resolve mapped paper IDs in the target.
        String query = "SELECT \"PaperId\",\"CustomUserId\",\"FirstViewed\",\"ViewedDate\" FROM legacy_boardpac.\"dbo__PaperDecisionViews\" WHERE \"FirstViewed\" IS NOT NULL OR \"ViewedDate\" IS NOT NULL ORDER BY \"PaperId\",\"CustomUserId\"";
        String insert = "INSERT INTO paper_read_states(paper_id,user_id,first_opened_at,last_opened_at,last_page,completed) VALUES (?,?,?,?,1,false)";
        int linked = 0, unplaced = 0;
        try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
             PreparedStatement hasPaper = target.prepareStatement("SELECT 1 FROM papers WHERE id=?");
             PreparedStatement write = target.prepareStatement(insert)) {
            while (row.next()) {
                long paper = row.getLong(1), user = row.getLong(2);
                hasPaper.setLong(1, paper);
                try (ResultSet found = hasPaper.executeQuery()) {
                    if (!found.next()) {
                        unplaced++;
                        continue;
                    }
                }
                Timestamp first = row.getTimestamp(3), last = row.getTimestamp(4);
                if (first == null) first = last;
                if (last == null || last.before(first)) last = first;
                write.setLong(1, paper);
                write.setLong(2, user);
                write.setTimestamp(3, first);
                write.setTimestamp(4, last);
                write.executeUpdate();
                linked++;
            }
        }
        if (linked + unplaced != 12915 || unplaced != 538)
            throw new SQLException("Unexpected legacy paper view counts: linked=" + linked + ", unplaced=" + unplaced);
        issue(target, "paper_read_states", 0,
                unplaced + " legacy view records for unplaced papers remain in staging until paper placement is resolved.");
        System.out.println("paper_read_states -> " + linked + "; unplaced paper views staged -> " + unplaced);
    }

    private static void requireEmpty(Connection db, String table) throws SQLException {
        try (Statement s = db.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM " + table)) {
            r.next();
            if (r.getLong(1) != 0) throw new SQLException("Destination " + table + " is not empty");
        }
    }
    private static void requireMap(Connection db, String entity, long count) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("SELECT count(*) FROM legacy_import_map WHERE entity=?")) {
            p.setString(1, entity);
            try (ResultSet r = p.executeQuery()) { r.next(); if (r.getLong(1) != count) throw new SQLException("Missing " + entity + " import"); }
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
    private static String decode(byte[] bytes) {
        return bytes == null ? null : new String(bytes, java.nio.charset.StandardCharsets.UTF_8).replace("\u0000", "").trim();
    }
    private static String limit(String text, int max) { return text.length() <= max ? text : text.substring(0, max); }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
