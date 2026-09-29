package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.util.*;

/** Loads decrypted legacy headings and meeting-linked papers into an isolated app database. */
public final class LegacyAgendaMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL");
        String targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        Path textFile = Path.of(required("MIGRATION_DECRYPTED_TEXT"));
        Map<Long, String> headings = new HashMap<>();
        Map<Long, String> papers = new HashMap<>();
        for (String line : Files.readAllLines(textFile, StandardCharsets.UTF_8)) {
            String[] fields = line.split("\\t", -1);
            if (fields.length != 3) throw new IllegalArgumentException("Invalid decrypted text row");
            long id = Long.parseLong(fields[1]);
            String value = new String(Base64.getDecoder().decode(fields[2]), StandardCharsets.UTF_8);
            Map<Long, String> destination = switch (fields[0]) {
                case "heading" -> headings;
                case "paper" -> papers;
                default -> throw new IllegalArgumentException("Unknown decrypted text kind");
            };
            if (destination.put(id, value) != null) throw new IllegalArgumentException("Duplicate decrypted text ID");
        }
        if (headings.size() != 1462 || papers.size() != 5084)
            throw new IllegalArgumentException("Unexpected decrypted text counts: headings=" + headings.size() + ", papers=" + papers.size());
        try (Connection source = DriverManager.getConnection(sourceUrl, required("MIGRATION_PG_USER"), required("MIGRATION_PG_PASSWORD"));
             Connection target = DriverManager.getConnection(targetUrl, required("MIGRATION_PG_USER"), required("MIGRATION_PG_PASSWORD"))) {
            target.setAutoCommit(false);
            try {
                requireCore(target);
                importHeadings(source, target, headings);
                importPapers(source, target, papers);
                for (String table : List.of("agenda_sections", "agenda_items", "papers")) {
                    try (Statement s = target.createStatement()) {
                        s.execute("SELECT setval(pg_get_serial_sequence('" + table + "','id'), (SELECT max(id) FROM " + table + "))");
                    }
                }
                target.commit();
            } catch (Exception e) {
                target.rollback();
                throw e;
            }
        }
    }

    private static void requireCore(Connection target) throws SQLException {
        for (String table : List.of("agenda_sections", "agenda_items", "papers")) {
            try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM " + table)) {
                r.next();
                if (r.getLong(1) != 0) throw new SQLException("Destination " + table + " is not empty");
            }
        }
        try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM legacy_import_map WHERE entity='meetings'")) {
            r.next();
            if (r.getLong(1) != 158) throw new SQLException("Core meeting import has not completed");
        }
    }

    private static void importHeadings(Connection source, Connection target, Map<Long, String> names) throws SQLException {
        int count = 0;
        String sql = "SELECT \"HeadingId\",\"MeetingId\",\"AgendaOrder\",\"PreviousHeadingId\" FROM legacy_boardpac.\"dbo__Headings\" ORDER BY \"HeadingId\"";
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(sql);
             PreparedStatement insert = target.prepareStatement("INSERT INTO agenda_sections (id,meeting_id,title,display_order) VALUES (?,?,?,?)")) {
            while (r.next()) {
                long id = r.getLong(1);
                String title = names.get(id);
                if (title == null || title.isBlank()) throw new SQLException("Missing decrypted heading " + id);
                if (clean(title).length() > 255) issue(target, "agenda_sections", id, "Decrypted title exceeds destination 255-character limit; display title truncated.");
                insert.setLong(1, id);
                insert.setLong(2, r.getLong(2));
                insert.setString(3, limit(clean(title), 255));
                nullableInt(insert, 4, r, 3);
                insert.executeUpdate();
                map(target, "agenda_sections", id);
                int previous = r.getInt(4);
                if (!r.wasNull() && previous != 0) issue(target, "agenda_sections", id, "Legacy previous heading " + previous + " retained in staging; destination sections are flat.");
                count++;
            }
        }
        if (count != names.size()) throw new SQLException("Heading count mismatch");
        System.out.println("agenda_sections -> " + count);
    }

    private static void importPapers(Connection source, Connection target, Map<Long, String> names) throws SQLException {
        int linked = 0, unlinked = 0;
        String query = "SELECT p.\"PaperId\",p.\"HeadingId\",h.\"MeetingId\",p.\"DocType\",p.\"PaperRefNo\",p.\"AgendaOrder\",p.\"Info1\",p.\"CreatedDate\",p.\"ModifiedDate\" FROM legacy_boardpac.\"dbo__Papers\" p LEFT JOIN legacy_boardpac.\"dbo__Headings\" h ON h.\"HeadingId\"=p.\"HeadingId\" ORDER BY p.\"PaperId\"";
        String itemSql = "INSERT INTO agenda_items (id,meeting_id,section_id,item_type,title,display_order,created_at,updated_at) VALUES (?,?,?,'PAPER',?,?,?,?)";
        String paperSql = "INSERT INTO papers (id,meeting_id,agenda_item_id,paper_type,title,reference_number,file_path,file_name,version_number,requires_approval,is_main_paper,created_at,updated_at) VALUES (?,?,?,?,?,?,NULL,NULL,1,false,?,?,?)";
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(query);
             PreparedStatement item = target.prepareStatement(itemSql);
             PreparedStatement paper = target.prepareStatement(paperSql)) {
            while (r.next()) {
                long id = r.getLong(1);
                String title = names.get(id);
                if (title == null || title.isBlank()) throw new SQLException("Missing decrypted paper " + id);
                long meeting = r.getLong(3);
                if (r.wasNull()) {
                    issue(target, "papers", id, "No legacy heading/meeting link; paper kept in staging until its placement is resolved.");
                    unlinked++;
                    continue;
                }
                long heading = r.getLong(2);
                if (clean(title).length() > 255) issue(target, "papers", id, "Decrypted title exceeds destination 255-character limit; display title truncated.");
                String type = paperType(r.getInt(4));
                if (type == null) {
                    issue(target, "papers", id, "Unknown legacy DocType " + r.getInt(4) + "; imported as SUPPORTING_DOCUMENT pending review.");
                    type = "SUPPORTING_DOCUMENT";
                }
                String cleanTitle = limit(clean(title), 255);
                Timestamp created = r.getTimestamp(8), updated = r.getTimestamp(9);
                item.setLong(1, id);
                item.setLong(2, meeting);
                item.setLong(3, heading);
                item.setString(4, cleanTitle);
                nullableInt(item, 5, r, 6);
                item.setTimestamp(6, created);
                item.setTimestamp(7, updated);
                item.executeUpdate();
                paper.setLong(1, id);
                paper.setLong(2, meeting);
                paper.setLong(3, id);
                paper.setString(4, type);
                paper.setString(5, cleanTitle);
                String reference = decodeUtf16(r.getBytes(5));
                if (reference != null && reference.length() > 255) issue(target, "papers", id, "Reference number exceeds destination 255-character limit; value truncated.");
                paper.setString(6, limit(reference, 255));
                paper.setBoolean(7, r.getInt(4) != 3);
                paper.setTimestamp(8, created);
                paper.setTimestamp(9, updated);
                paper.executeUpdate();
                map(target, "agenda_items", id);
                map(target, "papers", id);
                linked++;
            }
        }
        if (linked + unlinked != names.size()) throw new SQLException("Paper count mismatch");
        System.out.println("agenda_items + papers -> " + linked + "; unlinked staged -> " + unlinked);
    }

    private static String paperType(int value) {
        return switch (value) {
            case 0, 6 -> "APPROVAL";
            case 1 -> "INFORMATION";
            case 2 -> "DISCUSSION_ITEM";
            case 3 -> "SUPPORTING_DOCUMENT";
            case 4 -> "DISCUSSION_PAPER";
            default -> null;
        };
    }
    private static String decodeUtf16(byte[] b) { return b == null ? null : clean(new String(b, StandardCharsets.UTF_16LE)); }
    private static String clean(String s) { return s == null ? null : s.replace("\u0000", "").replaceAll("[\\p{Cntrl}&&[^\\r\\n\\t]]", "").trim(); }
    private static String limit(String s, int n) { return s == null ? null : s.length() > n ? s.substring(0, n) : s; }
    private static void nullableInt(PreparedStatement p, int at, ResultSet r, int col) throws SQLException { int n = r.getInt(col); if (r.wasNull()) p.setNull(at, Types.INTEGER); else p.setInt(at, n); }
    private static void map(Connection db, String entity, long id) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_map VALUES (?,?,?)")) { p.setString(1, entity); p.setLong(2, id); p.setLong(3, id); p.executeUpdate(); }
    }
    private static void issue(Connection db, String entity, long id, String issue) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_issues VALUES (?,?,?)")) { p.setString(1, entity); p.setLong(2, id); p.setString(3, issue); p.executeUpdate(); }
    }
    private static String required(String key) { String v = System.getenv(key); if (v == null || v.isBlank()) throw new IllegalArgumentException("Missing " + key); return v; }
}
