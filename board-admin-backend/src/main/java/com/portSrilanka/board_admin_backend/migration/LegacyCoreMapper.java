package com.portSrilanka.board_admin_backend.migration;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;
import org.flywaydb.core.Flyway;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** Imports only clear, independently verifiable core records from legacy staging.
 *  The source's encrypted headings and papers require the original decryption code.
 */
public final class LegacyCoreMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL");
        String targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER");
        String password = required("MIGRATION_PG_PASSWORD");
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            requireEmpty(target);
            try {
                createAudit(target);
                importUsers(source, target);
                importCategories(source, target);
                importSubcategories(source, target);
                importMeetings(source, target);
                resetSequences(target);
                target.commit();
            } catch (Exception e) {
                target.rollback();
                throw e;
            }
        }
    }

    private static void requireEmpty(Connection target) throws SQLException {
        for (String table : List.of("users", "categories", "subcategories", "meetings", "agenda_sections", "agenda_items", "papers")) {
            try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM " + table)) {
                r.next();
                if (r.getLong(1) != 0) throw new SQLException("Destination " + table + " is not empty");
            }
        }
    }

    private static void createAudit(Connection target) throws SQLException {
        try (Statement s = target.createStatement()) {
            s.execute("CREATE TABLE legacy_import_map (entity varchar(40) NOT NULL, legacy_id bigint NOT NULL, app_id bigint NOT NULL, PRIMARY KEY(entity, legacy_id))");
            s.execute("CREATE TABLE legacy_import_issues (entity varchar(40) NOT NULL, legacy_id bigint NOT NULL, issue text NOT NULL)");
        }
    }

    private static void importUsers(Connection source, Connection target) throws SQLException {
        String query = "SELECT \"CustomUserId\",\"UserName\",\"FirstName\",\"LastName\",\"DisplayName\",\"BoardEmail\",\"OfficeEmail\",\"OfficePhone\",\"MobileNumber\",\"JobTitle\",\"CreatedDate\",\"ModifiedDate\" FROM legacy_boardpac.\"dbo__Users\" ORDER BY \"CustomUserId\"";
        String insert = "INSERT INTO users (id,username,password,first_name,last_name,display_name,board_email,office_email,office_number,mobile_number,job_title,board_type,status,access_profile,two_step_enabled,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,'MEMBER','DEACTIVATED','MEMBER',false,?,?)";
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        Set<String> usedEmails = new HashSet<>();
        Set<String> usedNames = new HashSet<>();
        int count = 0;
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement(insert)) {
            while (r.next()) {
                long id = r.getLong(1);
                String username = text(r, 2);
                if (username == null || username.isBlank()) username = "legacy-user-" + id;
                if (!usedNames.add(username.toLowerCase(Locale.ROOT))) throw new SQLException("Duplicate username at legacy user " + id);
                String email = text(r, 6);
                if (email == null || email.isBlank() || !usedEmails.add(email.toLowerCase(Locale.ROOT))) {
                    issue(target, "users", id, "Missing or duplicate board email; original retained in staging. Assigned migration.invalid address.");
                    email = "legacy-" + id + "@migration.invalid";
                }
                write.setLong(1, id);
                write.setString(2, limit(username, 255));
                write.setString(3, encoder.encode(UUID.randomUUID().toString()));
                write.setString(4, fallback(limit(text(r, 3), 255), "Legacy"));
                write.setString(5, fallback(limit(text(r, 4), 255), "User"));
                write.setString(6, limit(text(r, 5), 255));
                write.setString(7, limit(email, 255));
                write.setString(8, limit(text(r, 7), 255));
                write.setString(9, limit(text(r, 8), 100));
                write.setString(10, limit(text(r, 9), 100));
                write.setString(11, limit(text(r, 10), 255));
                write.setTimestamp(12, r.getTimestamp(11));
                write.setTimestamp(13, r.getTimestamp(12));
                write.executeUpdate();
                map(target, "users", id);
                count++;
            }
        }
        System.out.println("users -> " + count + " (disabled; passwords reset required)");
    }

    private static void importCategories(Connection source, Connection target) throws SQLException {
        Set<String> names = new HashSet<>();
        int count = 0;
        try (Statement read = source.createStatement();
             ResultSet r = read.executeQuery("SELECT \"CategoryId\",\"Name\",\"CategoryOrder\" FROM legacy_boardpac.\"dbo__Categories\" ORDER BY \"CategoryId\"");
             PreparedStatement write = target.prepareStatement("INSERT INTO categories (id,name,display_name,display_order) VALUES (?,?,?,?)")) {
            while (r.next()) {
                long id = r.getLong(1);
                String display = fallback(limit(text(r, 2), 255), "Legacy category " + id);
                String name = display;
                if (!names.add(name.toLowerCase(Locale.ROOT))) {
                    name = limit(display, 220) + " (legacy " + id + ")";
                    issue(target, "categories", id, "Duplicate category name; unique suffix added.");
                }
                write.setLong(1, id);
                write.setString(2, name);
                write.setString(3, display);
                nullableInt(write, 4, r, 3);
                write.executeUpdate();
                map(target, "categories", id);
                count++;
            }
        }
        System.out.println("categories -> " + count);
    }

    private static void importSubcategories(Connection source, Connection target) throws SQLException {
        int count = 0;
        try (Statement read = source.createStatement();
             ResultSet r = read.executeQuery("SELECT \"SubCategoryId\",\"Name\",\"SubCategoryOrder\",\"CategoryId\" FROM legacy_boardpac.\"dbo__SubCategories\" ORDER BY \"SubCategoryId\"");
             PreparedStatement write = target.prepareStatement("INSERT INTO subcategories (id,name,display_name,display_order,category_id) VALUES (?,?,?,?,?)")) {
            while (r.next()) {
                long id = r.getLong(1);
                String name = fallback(limit(text(r, 2), 255), "Legacy subcategory " + id);
                write.setLong(1, id);
                write.setString(2, name);
                write.setString(3, name);
                nullableInt(write, 4, r, 3);
                write.setLong(5, r.getLong(4));
                write.executeUpdate();
                map(target, "subcategories", id);
                count++;
            }
        }
        System.out.println("subcategories -> " + count);
    }

    private static void importMeetings(Connection source, Connection target) throws SQLException {
        int count = 0;
        String query = "SELECT m.\"MeetingId\",m.\"Title\",m.\"Subject\",m.\"Description\",m.\"MeetingType\",m.\"Status\",m.\"Date\",m.\"StartTime\",m.\"Venue\",m.\"Address\",m.\"SubCategoryId\",s.\"CategoryId\",m.\"CreatedBy\",m.\"CreatedDate\",m.\"ModifiedDate\" FROM legacy_boardpac.\"dbo__Meetings\" m JOIN legacy_boardpac.\"dbo__SubCategories\" s ON s.\"SubCategoryId\"=m.\"SubCategoryId\" ORDER BY m.\"MeetingId\"";
        String insert = "INSERT INTO meetings (id,title,type,status,meeting_date_time,location,description,category_id,subcategory_id,created_by,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(query);
             PreparedStatement write = target.prepareStatement(insert)) {
            while (r.next()) {
                long id = r.getLong(1);
                String title = fallback(limit(text(r, 2), 255), fallback(limit(text(r, 3), 255), "Legacy meeting " + id));
                // Keep all imported meetings in DRAFT until the legacy numeric statuses and access rules are reviewed.
                write.setLong(1, id);
                write.setString(2, title);
                write.setString(3, r.getInt(5) == 1 ? "CIRCULAR" : "MEETING");
                write.setString(4, "DRAFT");
                Timestamp when = r.getTimestamp(7);
                Time start = r.getTime(8);
                if (when != null && start != null) when = Timestamp.valueOf(when.toLocalDateTime().toLocalDate().atTime(start.toLocalTime()));
                write.setTimestamp(5, when);
                write.setString(6, limit(fallback(text(r, 9), text(r, 10)), 255));
                write.setString(7, limit(text(r, 4), 3000));
                write.setLong(8, r.getLong(12));
                write.setLong(9, r.getLong(11));
                write.setLong(10, r.getLong(13));
                write.setTimestamp(11, r.getTimestamp(14));
                write.setTimestamp(12, r.getTimestamp(15));
                write.executeUpdate();
                map(target, "meetings", id);
                issue(target, "meetings", id, "Legacy status " + r.getInt(6) + " staged; destination held in DRAFT pending status and permissions mapping.");
                count++;
            }
        }
        System.out.println("meetings -> " + count + " (DRAFT pending status mapping)");
    }

    private static void nullableInt(PreparedStatement p, int parameter, ResultSet r, int column) throws SQLException {
        int n = r.getInt(column);
        if (r.wasNull()) p.setNull(parameter, Types.INTEGER); else p.setInt(parameter, n);
    }

    private static String text(ResultSet r, int column) throws SQLException {
        byte[] bytes = r.getBytes(column);
        if (bytes == null) return null;
        try {
            String value = StandardCharsets.UTF_16LE.newDecoder().decode(ByteBuffer.wrap(bytes)).toString();
            return value.replace("\u0000", "").replaceAll("[\\p{Cntrl}&&[^\\r\\n\\t]]", "").trim();
        } catch (CharacterCodingException e) { throw new SQLException("Invalid UTF-16LE at column " + column, e); }
    }

    private static String limit(String s, int max) { return s == null ? null : s.length() > max ? s.substring(0, max) : s; }
    private static String fallback(String value, String fallback) { return value == null || value.isBlank() ? fallback : value; }
    private static void map(Connection db, String entity, long id) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_map VALUES (?,?,?)")) {
            p.setString(1, entity); p.setLong(2, id); p.setLong(3, id); p.executeUpdate();
        }
    }
    private static void issue(Connection db, String entity, long id, String issue) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_issues VALUES (?,?,?)")) {
            p.setString(1, entity); p.setLong(2, id); p.setString(3, issue); p.executeUpdate();
        }
    }
    private static void resetSequences(Connection db) throws SQLException {
        try (Statement s = db.createStatement()) {
            for (String table : List.of("users", "categories", "subcategories", "meetings"))
                s.execute("SELECT setval(pg_get_serial_sequence('" + table + "','id'), (SELECT max(id) FROM " + table + "))");
        }
    }
    private static String required(String key) { String v = System.getenv(key); if (v == null || v.isBlank()) throw new IllegalArgumentException("Missing " + key); return v; }
}
