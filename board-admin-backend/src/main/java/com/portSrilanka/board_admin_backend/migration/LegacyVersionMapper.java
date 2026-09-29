package com.portSrilanka.board_admin_backend.migration;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import org.flywaydb.core.Flyway;

/** Preserves all legacy version metadata without changing the new paper workflow. */
public final class LegacyVersionMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            try {
                try (Statement check = target.createStatement(); ResultSet result = check.executeQuery("SELECT count(*) FROM legacy_document_versions")) {
                    result.next(); if (result.getLong(1) != 0) throw new SQLException("Version archive is not empty");
                }
                String query = "SELECT \"VersionId\",\"PreviousVersionId\",\"FilePath\",\"CreatedBy\",\"CreatedDate\",\"ModifiedBy\",\"ModifiedDate\",\"Info1\",\"Info2\",\"Info3\" FROM legacy_boardpac.\"dbo__DocVersions\" ORDER BY \"VersionId\"";
                String insert = "INSERT INTO legacy_document_versions(version_id,previous_version_id,source_file_path,created_by,created_at,modified_by,updated_at,info1,info2,info3) VALUES (?,?,?,?,?,?,?,?,?,?)";
                int count = 0;
                try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
                     PreparedStatement write = target.prepareStatement(insert)) {
                    while (row.next()) {
                        write.setLong(1, row.getLong(1));
                        setLong(write, 2, row, 2);
                        write.setString(3, decode(row.getBytes(3), Charset.forName("windows-1252")));
                        setLong(write, 4, row, 4);
                        write.setTimestamp(5, row.getTimestamp(5));
                        setLong(write, 6, row, 6);
                        write.setTimestamp(7, row.getTimestamp(7));
                        write.setString(8, decode(row.getBytes(8), StandardCharsets.UTF_16LE));
                        write.setString(9, decode(row.getBytes(9), StandardCharsets.UTF_16LE));
                        int info = row.getInt(10);
                        if (row.wasNull()) write.setNull(10, Types.INTEGER); else write.setInt(10, info);
                        write.addBatch();
                        if (++count % 500 == 0) write.executeBatch();
                    }
                    write.executeBatch();
                }
                if (count != 5111) throw new SQLException("Unexpected legacy version count: " + count);
                target.commit();
                System.out.println("legacy_document_versions -> " + count + " (metadata; original encrypted content remains staged)");
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }
    private static void setLong(PreparedStatement write, int at, ResultSet row, int sourceColumn) throws SQLException {
        long value = row.getLong(sourceColumn);
        if (row.wasNull()) write.setNull(at, Types.BIGINT); else write.setLong(at, value);
    }
    private static String decode(byte[] bytes, Charset charset) {
        return bytes == null ? null : new String(bytes, charset).replace("\u0000", "").trim();
    }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
