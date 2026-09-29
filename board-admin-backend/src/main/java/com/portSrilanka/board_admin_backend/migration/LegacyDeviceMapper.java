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

/** Copies old device inventory as history without approving devices in the new app. */
public final class LegacyDeviceMapper {
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
                try (Statement check = target.createStatement(); ResultSet r = check.executeQuery("SELECT count(*) FROM legacy_device_inventory")) {
                    r.next(); if (r.getLong(1) != 0) throw new SQLException("Legacy device inventory is not empty");
                }
                String query = "SELECT \"Id\",\"DeviceId\",\"MacAddress\",\"Status\",\"Description\",\"DeviceInfo\",\"IpadVersion\",\"DeviceOS\",\"DeviceType\",\"IsAllocatedForDS\",\"EnableDeviceLog\",\"LastVersionUpdatedDate\" FROM legacy_boardpac.\"dbo__Devices\" ORDER BY \"Id\"";
                String insert = "INSERT INTO legacy_device_inventory(source_id,device_identifier,mac_address,status_code,description,device_info,version,os_name,device_type_code,allocated_for_signature_code,enable_device_log,last_version_updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
                int count = 0;
                try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
                     PreparedStatement write = target.prepareStatement(insert)) {
                    while (row.next()) {
                        write.setLong(1, row.getLong(1));
                        for (int index : new int[]{2,3,5,6}) write.setString(index, decode(row.getBytes(index), StandardCharsets.UTF_16LE));
                        setInt(write, 4, row, 4);
                        write.setString(7, decode(row.getBytes(7), Charset.forName("windows-1252")));
                        write.setString(8, decode(row.getBytes(8), Charset.forName("windows-1252")));
                        setInt(write, 9, row, 9);
                        setInt(write, 10, row, 10);
                        boolean logging = row.getBoolean(11);
                        if (row.wasNull()) write.setNull(11, Types.BOOLEAN); else write.setBoolean(11, logging);
                        write.setTimestamp(12, row.getTimestamp(12));
                        write.executeUpdate();
                        count++;
                    }
                }
                if (count != 23) throw new SQLException("Unexpected legacy device count: " + count);
                target.commit();
                System.out.println("legacy_device_inventory -> " + count + " (read-only; no devices approved)");
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }
    private static void setInt(PreparedStatement p, int at, ResultSet row, int column) throws SQLException {
        int value = row.getInt(column);
        if (row.wasNull()) p.setNull(at, Types.INTEGER); else p.setInt(at, value);
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
