package com.portSrilanka.board_admin_backend.migration;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.sql.*;
import java.util.*;

/** Verifies extracted legacy files and links meeting-linked papers to the app file route. */
public final class LegacyFileLinker {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL");
        String targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        Path root = Path.of(required("MIGRATION_UPLOAD_ROOT")).toAbsolutePath().normalize();
        Path manifest = Path.of(required("MIGRATION_FILE_MANIFEST"));
        Path errors = Path.of(required("MIGRATION_FILE_ERRORS"));
        String baseUrl = required("MIGRATION_FILE_BASE_URL").replaceAll("/+$", "");
        if (!baseUrl.startsWith("http://") && !baseUrl.startsWith("https://"))
            throw new IllegalArgumentException("MIGRATION_FILE_BASE_URL must be HTTP(S)");
        try (Connection source = DriverManager.getConnection(sourceUrl, required("MIGRATION_PG_USER"), required("MIGRATION_PG_PASSWORD"));
             Connection target = DriverManager.getConnection(targetUrl, required("MIGRATION_PG_USER"), required("MIGRATION_PG_PASSWORD"))) {
            target.setAutoCommit(false);
            try {
                int linked = 0, unmatched = 0;
                List<String> lines = Files.readAllLines(manifest, StandardCharsets.UTF_8);
                if (lines.isEmpty() || !lines.get(0).equals("paper_id\tversion_id\trelative_path\tbytes\tsha256"))
                    throw new IllegalArgumentException("Invalid file manifest header");
                Set<Long> seenVersions = new HashSet<>();
                for (int i = 1; i < lines.size(); i++) {
                    String[] f = lines.get(i).split("\t", -1);
                    if (f.length != 5) throw new IllegalArgumentException("Invalid manifest row " + (i + 1));
                    long paperId = Long.parseLong(f[0]), versionId = Long.parseLong(f[1]);
                    if (!seenVersions.add(versionId)) throw new IllegalArgumentException("Duplicate version " + versionId);
                    if (!f[2].matches("legacy-papers/[0-9]+_[0-9]+\\.(pdf|pptx)"))
                        throw new IllegalArgumentException("Invalid relative file path");
                    Path file = root.resolve(f[2]).normalize();
                    if (!file.startsWith(root) || !Files.isRegularFile(file)) throw new IllegalArgumentException("Missing file: " + f[2]);
                    long expectedLength = Long.parseLong(f[3]);
                    if (Files.size(file) != expectedLength) throw new IllegalArgumentException("File length mismatch: " + f[2]);
                    if (!sha256(file).equalsIgnoreCase(f[4])) throw new IllegalArgumentException("File hash mismatch: " + f[2]);
                    if (!sourceVersionMatches(source, paperId, versionId)) throw new IllegalArgumentException("Source paper/version mismatch: " + paperId);
                    String route = baseUrl + "/api/files/content/" + Base64.getUrlEncoder().withoutPadding()
                            .encodeToString(f[2].getBytes(StandardCharsets.UTF_8));
                    String name = "legacy-paper-" + paperId + (f[2].endsWith(".pdf") ? ".pdf" : ".pptx");
                    try (PreparedStatement update = target.prepareStatement("UPDATE papers SET file_path=?, file_name=? WHERE id=? AND file_path IS NULL")) {
                        update.setString(1, route);
                        update.setString(2, name);
                        update.setLong(3, paperId);
                        if (update.executeUpdate() == 1) linked++;
                        else {
                            issue(target, "paper_files", paperId, "Decrypted version " + versionId + " has no imported meeting-linked paper; file remains on disk.");
                            unmatched++;
                        }
                    }
                    if (i % 500 == 0) System.out.println("Verified " + i + " files");
                }
                List<String> errorLines = Files.readAllLines(errors, StandardCharsets.UTF_8);
                if (errorLines.isEmpty() || !errorLines.get(0).equals("paper_id\tversion_id\tproblem"))
                    throw new IllegalArgumentException("Invalid file error manifest header");
                for (int i = 1; i < errorLines.size(); i++) {
                    String[] f = errorLines.get(i).split("\t", -1);
                    if (f.length != 3 || !Set.of("decryption_failed", "unknown_signature").contains(f[2]))
                        throw new IllegalArgumentException("Invalid file error row " + (i + 1));
                    long paperId = Long.parseLong(f[0]), versionId = Long.parseLong(f[1]);
                    if (!seenVersions.add(versionId) || !sourceVersionMatches(source, paperId, versionId))
                        throw new IllegalArgumentException("Duplicate or mismatched error version " + versionId);
                    issue(target, "paper_files", paperId, "Legacy version " + versionId + " could not be exported: " + f[2]);
                }
                int expected = Integer.parseInt(System.getenv().getOrDefault("MIGRATION_EXPECTED_SOURCE_FILE_COUNT", "4781"));
                if (seenVersions.size() != expected) throw new IllegalArgumentException("Expected " + expected + " paper-linked file versions; found " + seenVersions.size());
                target.commit();
                System.out.println("Linked " + linked + " paper files; staged " + unmatched + " for unlinked papers; export failures " + (errorLines.size() - 1));
            } catch (Exception e) {
                target.rollback();
                throw e;
            }
        }
    }

    private static boolean sourceVersionMatches(Connection source, long paper, long version) throws SQLException {
        try (PreparedStatement p = source.prepareStatement("SELECT 1 FROM legacy_boardpac.\"dbo__Papers\" WHERE \"PaperId\"=? AND \"VersionId\"=?")) {
            p.setLong(1, paper); p.setLong(2, version);
            try (ResultSet r = p.executeQuery()) { return r.next(); }
        }
    }
    private static String sha256(Path file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream in = Files.newInputStream(file)) {
            byte[] buffer = new byte[1024 * 1024];
            int n;
            while ((n = in.read(buffer)) > 0) digest.update(buffer, 0, n);
        }
        return HexFormat.of().formatHex(digest.digest());
    }
    private static void issue(Connection db, String entity, long id, String issue) throws SQLException {
        try (PreparedStatement p = db.prepareStatement("INSERT INTO legacy_import_issues VALUES (?,?,?)")) { p.setString(1, entity); p.setLong(2, id); p.setString(3, issue); p.executeUpdate(); }
    }
    private static String required(String key) { String v = System.getenv(key); if (v == null || v.isBlank()) throw new IllegalArgumentException("Missing " + key); return v; }
}
