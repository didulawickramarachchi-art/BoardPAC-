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
import java.util.Map;
import org.flywaydb.core.Flyway;

/** Keeps papers without a meeting in a separate, read-only application archive. */
public final class LegacyArchiveMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        Map<Long, String> titles = titles(Path.of(required("MIGRATION_DECRYPTED_TEXT")));
        Map<Long, FileInfo> files = files(Path.of(required("MIGRATION_FILE_MANIFEST")));
        Path root = Path.of(required("MIGRATION_UPLOAD_ROOT")).toAbsolutePath().normalize();
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            try {
                try (Statement s = target.createStatement(); ResultSet r = s.executeQuery("SELECT count(*) FROM legacy_paper_archive")) {
                    r.next(); if (r.getLong(1) != 0) throw new SQLException("Legacy archive is not empty");
                }
                int count = 0, linked = 0;
                String query = "SELECT p.\"PaperId\",p.\"HeadingId\",p.\"VersionId\",p.\"DocType\",p.\"PaperRefNo\",p.\"CreatedDate\",p.\"ModifiedDate\" "
                        + "FROM legacy_boardpac.\"dbo__Papers\" p LEFT JOIN legacy_boardpac.\"dbo__Headings\" h "
                        + "ON h.\"HeadingId\"=p.\"HeadingId\" WHERE h.\"MeetingId\" IS NULL ORDER BY p.\"PaperId\"";
                String insert = "INSERT INTO legacy_paper_archive(paper_id,title,reference_number,source_heading_id,source_version_id,source_doc_type,file_relative_path,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?)";
                try (Statement read = source.createStatement(); ResultSet row = read.executeQuery(query);
                     PreparedStatement write = target.prepareStatement(insert);
                     PreparedStatement map = target.prepareStatement("INSERT INTO legacy_import_map VALUES ('legacy_paper_archive',?,?)")) {
                    while (row.next()) {
                        long id = row.getLong(1);
                        String title = titles.get(id);
                        if (title == null || title.isBlank()) throw new SQLException("Missing decrypted paper title " + id);
                        long version = row.getLong(3);
                        FileInfo file = row.wasNull() ? null : files.get(version);
                        if (file != null && file.paperId != id) throw new SQLException("File/paper mismatch " + id);
                        if (file != null && !Files.isRegularFile(root.resolve(file.path).normalize()))
                            throw new SQLException("Missing archived document " + id);
                        write.setLong(1, id);
                        write.setString(2, limit(clean(title), 255));
                        write.setString(3, limit(decode(row.getBytes(5)), 255));
                        long heading = row.getLong(2);
                        if (row.wasNull()) write.setNull(4, java.sql.Types.BIGINT); else write.setLong(4, heading);
                        if (version == 0) write.setNull(5, java.sql.Types.BIGINT); else write.setLong(5, version);
                        write.setInt(6, row.getInt(4));
                        write.setString(7, file == null ? null : file.path);
                        write.setTimestamp(8, row.getTimestamp(6));
                        write.setTimestamp(9, row.getTimestamp(7));
                        write.executeUpdate();
                        map.setLong(1, id); map.setLong(2, id); map.executeUpdate();
                        count++;
                        if (file != null) linked++;
                    }
                }
                if (count != 939) throw new SQLException("Expected 939 unplaced papers; found " + count);
                target.commit();
                System.out.println("legacy_paper_archive -> " + count + "; current files -> " + linked);
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }

    private static Map<Long, String> titles(Path path) throws Exception {
        Map<Long, String> values = new HashMap<>();
        for (String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
            String[] parts = line.split("\\t", -1);
            if (parts.length != 3) throw new IllegalArgumentException("Invalid decrypted text row");
            if (parts[0].equals("paper")) {
                long id = Long.parseLong(parts[1]);
                if (values.put(id, new String(Base64.getDecoder().decode(parts[2]), StandardCharsets.UTF_8)) != null)
                    throw new IllegalArgumentException("Duplicate paper title " + id);
            }
        }
        if (values.size() != 5084) throw new IllegalArgumentException("Unexpected decrypted paper title count");
        return values;
    }
    private static Map<Long, FileInfo> files(Path path) throws Exception {
        Map<Long, FileInfo> values = new HashMap<>();
        var lines = Files.readAllLines(path, StandardCharsets.UTF_8);
        if (lines.isEmpty() || !lines.get(0).equals("paper_id\tversion_id\trelative_path\tbytes\tsha256"))
            throw new IllegalArgumentException("Invalid file manifest");
        for (int i = 1; i < lines.size(); i++) {
            String[] parts = lines.get(i).split("\\t", -1);
            if (parts.length != 5 || !parts[2].matches("legacy-papers/[0-9]+_[0-9]+\\.(pdf|pptx)"))
                throw new IllegalArgumentException("Invalid file manifest row " + i);
            long version = Long.parseLong(parts[1]);
            if (values.put(version, new FileInfo(Long.parseLong(parts[0]), parts[2])) != null)
                throw new IllegalArgumentException("Duplicate file version " + version);
        }
        return values;
    }
    private record FileInfo(long paperId, String path) {}
    private static String decode(byte[] value) { return value == null ? null : clean(new String(value, StandardCharsets.UTF_16LE)); }
    private static String clean(String value) { return value == null ? null : value.replace("\u0000", "").replaceAll("[\\p{Cntrl}&&[^\\r\\n\\t]]", "").trim(); }
    private static String limit(String value, int max) { return value == null || value.length() <= max ? value : value.substring(0, max); }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}
