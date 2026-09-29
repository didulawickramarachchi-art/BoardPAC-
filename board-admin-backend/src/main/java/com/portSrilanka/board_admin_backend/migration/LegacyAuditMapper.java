package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import org.flywaydb.core.Flyway;

/** Copies old audit trails to separate read-only history. */
public final class LegacyAuditMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            source.setAutoCommit(false);
            target.setAutoCommit(false);
            try {
                try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM legacy_audit_events")) {
                    r.next(); if (r.getLong(1) != 0) throw new SQLException("Legacy audit history is not empty");
                }
                int system = importSystem(source, target), organization = importOrganization(source, target);
                if (system != 150003 || organization != 39803)
                    throw new SQLException("Unexpected audit counts: " + system + ", " + organization);
                target.commit();
                System.out.println("legacy_audit_events -> " + (system + organization) + " (read-only)");
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }

    private static int importSystem(Connection source, Connection target) throws SQLException {
        String select = "SELECT \"LogId\",\"EventNumber\",\"Event\",\"EventStatus\",\"Date\",\"UserName\",\"ControllerName\",\"ActionName\",\"Parameters\" FROM legacy_boardpac.\"dbo__AuditLogs\" ORDER BY \"LogId\"";
        String insert = "INSERT INTO legacy_audit_events(source_kind,source_id,event_number,event_text,event_status,username,module_name,action_name,parameters,event_time) VALUES ('SYSTEM',?,?,?,?,?,?,?,?,?)";
        int count = 0;
        try (Statement read = source.createStatement(); PreparedStatement write = target.prepareStatement(insert)) {
            read.setFetchSize(1000);
            try (ResultSet row = read.executeQuery(select)) {
                while (row.next()) {
                    write.setLong(1, row.getLong(1));
                    nullableInt(write, 2, row, 2);
                    write.setString(3, text(row, 3));
                    write.setString(4, text(row, 4));
                    write.setString(5, text(row, 6));
                    write.setString(6, text(row, 7));
                    write.setString(7, text(row, 8));
                    write.setString(8, text(row, 9));
                    write.setTimestamp(9, row.getTimestamp(5));
                    write.addBatch();
                    if (++count % 1000 == 0) write.executeBatch();
                }
            }
            write.executeBatch();
        }
        return count;
    }

    private static int importOrganization(Connection source, Connection target) throws SQLException {
        String select = "SELECT \"OrgAuditLogId\",\"CategoryId\",\"SubCategoryId\",\"MeetingId\",\"PaperId\",\"DeviceId\",\"Module\",\"Action\",\"Description\",\"CreatedBy\",\"CreatedDate\" FROM legacy_boardpac.\"dbo__OrgAuditLogs\" ORDER BY \"OrgAuditLogId\"";
        String insert = "INSERT INTO legacy_audit_events(source_kind,source_id,category_id,subcategory_id,meeting_id,paper_id,device_id,module_name,action_name,description,created_by,event_time) VALUES ('ORGANIZATION',?,?,?,?,?,?,?,?,?,?,?)";
        int count = 0;
        try (Statement read = source.createStatement(); PreparedStatement write = target.prepareStatement(insert)) {
            read.setFetchSize(1000);
            try (ResultSet row = read.executeQuery(select)) {
                while (row.next()) {
                    write.setLong(1, row.getLong(1));
                    for (int i = 2; i <= 6; i++) nullableLong(write, i, row, i);
                    write.setString(7, text(row, 7));
                    write.setString(8, text(row, 8));
                    write.setString(9, text(row, 9));
                    nullableLong(write, 10, row, 10);
                    write.setTimestamp(11, row.getTimestamp(11));
                    write.addBatch();
                    if (++count % 1000 == 0) write.executeBatch();
                }
            }
            write.executeBatch();
        }
        return count;
    }
    private static String text(ResultSet row, int column) throws SQLException {
        byte[] bytes = row.getBytes(column);
        return bytes == null ? null : new String(bytes, StandardCharsets.UTF_16LE).replace("\u0000", "").trim();
    }
    private static void nullableInt(PreparedStatement p, int at, ResultSet row, int column) throws SQLException {
        int value = row.getInt(column);
        if (row.wasNull()) p.setNull(at, Types.INTEGER); else p.setInt(at, value);
    }
    private static void nullableLong(PreparedStatement p, int at, ResultSet row, int column) throws SQLException {
        long value = row.getLong(column);
        if (row.wasNull()) p.setNull(at, Types.BIGINT); else p.setLong(at, value);
    }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
