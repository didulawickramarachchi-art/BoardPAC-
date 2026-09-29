package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

/** Maps legacy ASP.NET roles and explicit subcategory grants in an isolated app database. */
public final class LegacyAccessMapper {
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
                requireReady(target);
                int roles = importRoles(source, target);
                int grants = importAccess(source, target);
                target.commit();
                System.out.println("Mapped " + roles + " user roles and " + grants + " subcategory grants; users remain DEACTIVATED");
            } catch (Exception e) {
                target.rollback();
                throw e;
            }
        }
    }

    private static void requireReady(Connection db) throws SQLException {
        for (String table : List.of("user_roles", "user_subcategory_access")) {
            try (Statement s = db.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM " + table)) {
                r.next();
                if (r.getLong(1) != 0) throw new SQLException("Destination " + table + " is not empty");
            }
        }
        try (Statement s = db.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM legacy_import_map WHERE entity='users'")) {
            r.next();
            if (r.getLong(1) != 87) throw new SQLException("Core user import has not completed");
        }
    }

    private static int importRoles(Connection source, Connection target) throws SQLException {
        Map<String, Long> roleIds = new HashMap<>();
        try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT id,name FROM roles")) {
            while (r.next()) roleIds.put(r.getString(2), r.getLong(1));
        }
        for (String name : List.of("ADMIN", "SECRETARY", "MEMBER"))
            if (!roleIds.containsKey(name)) throw new SQLException("Missing target role " + name);
        String query = "SELECT u.\"CustomUserId\",r.\"RoleName\" FROM legacy_boardpac.\"dbo__Users\" u JOIN legacy_boardpac.\"dbo__aspnet_UsersInRoles\" ur ON ur.\"UserId\"=u.\"UserId\" JOIN legacy_boardpac.\"dbo__aspnet_Roles\" r ON r.\"RoleId\"=ur.\"RoleId\" ORDER BY u.\"CustomUserId\"";
        Set<Long> seen = new HashSet<>();
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(query);
             PreparedStatement add = target.prepareStatement("INSERT INTO user_roles (user_id,role_id) VALUES (?,?)");
             PreparedStatement update = target.prepareStatement("UPDATE users SET board_type=?,access_profile=? WHERE id=?")) {
            while (r.next()) {
                long id = r.getLong(1);
                if (!seen.add(id)) throw new SQLException("Multiple legacy broad roles for user " + id);
                String legacy = decode(r.getBytes(2));
                String role, profile, boardType;
                switch (legacy) {
                    case "Member" -> { role = "MEMBER"; profile = "MEMBER"; boardType = "MEMBER"; }
                    case "Organizer" -> { role = "SECRETARY"; profile = "BOARD_SECRETARY"; boardType = "ORGANIZER"; }
                    case "Support Team" -> {
                        role = "MEMBER"; profile = "MEMBER_VIEW_ONLY"; boardType = "MEMBER";
                        issue(target, "user_roles", id, "Legacy Support Team assigned MEMBER_VIEW_ONLY until its global privileges are reviewed.");
                    }
                    case "System Admin" -> { role = "ADMIN"; profile = "SYSTEM_ADMINISTRATOR"; boardType = "SUPPORT_TEAM"; }
                    case "Administrator" -> { role = "ADMIN"; profile = "BOARD_ADMINISTRATOR"; boardType = "SUPPORT_TEAM"; }
                    default -> throw new SQLException("Unmapped legacy broad role for user " + id + ": " + legacy);
                }
                add.setLong(1, id); add.setLong(2, roleIds.get(role)); add.executeUpdate();
                update.setString(1, boardType); update.setString(2, profile); update.setLong(3, id);
                if (update.executeUpdate() != 1) throw new SQLException("Missing imported user " + id);
            }
        }
        if (seen.size() != 87) throw new SQLException("Expected 87 user roles, got " + seen.size());
        // The source has one ASP.NET membership that has no corresponding dbo.Users record.
        issue(target, "user_roles", 0, "One legacy ASP.NET membership has no dbo.Users record and was not imported.");
        return seen.size();
    }

    private static int importAccess(Connection source, Connection target) throws SQLException {
        String query = "SELECT a.\"CustomUserId\",a.\"RefId\",a.\"IpadDisplayOrder\",r.\"RoleName\" FROM legacy_boardpac.\"dbo__Accesses\" a JOIN legacy_boardpac.\"dbo__aspnet_Roles\" r ON r.\"RoleId\"=a.\"RoleId\" WHERE a.\"Type\"=1 ORDER BY a.\"CustomUserId\",a.\"RefId\"";
        Set<String> seen = new HashSet<>();
        int count = 0;
        try (Statement read = source.createStatement(); ResultSet r = read.executeQuery(query);
             PreparedStatement add = target.prepareStatement("INSERT INTO user_subcategory_access (user_id,subcategory_id,assigned_role,display_sequence) VALUES (?,?,?,?)")) {
            while (r.next()) {
                long userId = r.getLong(1), subcategoryId = r.getLong(2);
                if (!seen.add(userId + ":" + subcategoryId)) throw new SQLException("Duplicate subcategory grant");
                String legacy = decode(r.getBytes(4));
                String role = switch (legacy) {
                    case "Board Member iPad" -> "MEMBER";
                    case "Board Secretary" -> "SECRETARY";
                    case "Board Secretary-Assistant" -> "SECRETARY_ASSISTANT";
                    default -> throw new SQLException("Unmapped scoped role: " + legacy);
                };
                add.setLong(1, userId); add.setLong(2, subcategoryId); add.setString(3, role);
                int order = r.getInt(3);
                if (r.wasNull()) add.setNull(4, Types.INTEGER); else add.setInt(4, order);
                add.executeUpdate();
                count++;
            }
        }
        if (count != 50) throw new SQLException("Expected 50 explicit subcategory grants, got " + count);
        try (Statement s = target.createStatement()) {
            s.execute("SELECT setval(pg_get_serial_sequence('user_subcategory_access','id'), (SELECT max(id) FROM user_subcategory_access))");
        }
        issue(target, "user_subcategory_access", 0, "Only 25 legacy users have explicit subcategory grants; review other users before activation.");
        return count;
    }

    private static String decode(byte[] bytes) { return bytes == null ? null : new String(bytes, StandardCharsets.UTF_16LE).trim(); }
    private static void issue(Connection db, String entity, long id, String issue) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_issues VALUES (?,?,?)")) { p.setString(1, entity); p.setLong(2, id); p.setString(3, issue); p.executeUpdate(); }
    }
    private static String required(String key) { String v = System.getenv(key); if (v == null || v.isBlank()) throw new IllegalArgumentException("Missing " + key); return v; }
}
