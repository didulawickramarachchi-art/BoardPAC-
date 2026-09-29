package com.portSrilanka.board_admin_backend.controller;

import com.portSrilanka.board_admin_backend.service.FileStorageService;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Read-only access to legacy papers whose meeting placement is unknown. */
@RestController
@RequestMapping("/api/legacy-archive/papers")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class LegacyPaperArchiveController {
    private final JdbcTemplate jdbc;
    private final FileStorageService files;

    @GetMapping
    public List<Map<String, Object>> list(@RequestParam(defaultValue = "0") int page) {
        if (page < 0 || page > 100000) throw new IllegalArgumentException("Invalid page");
        return jdbc.queryForList("SELECT paper_id,title,reference_number,meeting_id,meeting_title,placement,has_file "
                + "FROM (SELECT a.paper_id,a.title,a.reference_number,NULL::bigint AS meeting_id,"
                + "NULL::varchar AS meeting_title,'UNPLACED' AS placement,"
                + "(a.file_relative_path IS NOT NULL) AS has_file FROM legacy_paper_archive a "
                + "UNION ALL SELECT p.id,p.title,p.reference_number,p.meeting_id,m.title,'MEETING',"
                + "(p.file_path IS NOT NULL) FROM papers p JOIN meetings m ON m.id=p.meeting_id) x "
                + "ORDER BY paper_id LIMIT 100 OFFSET ?", page * 100);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> get(@PathVariable long id) {
        var rows = jdbc.queryForList("SELECT paper_id,title,reference_number,source_heading_id,source_version_id,"
                + "meeting_id,meeting_title,placement,has_file,created_at,updated_at FROM "
                + "(SELECT a.paper_id,a.title,a.reference_number,a.source_heading_id,a.source_version_id,"
                + "NULL::bigint AS meeting_id,NULL::varchar AS meeting_title,'UNPLACED' AS placement,"
                + "(a.file_relative_path IS NOT NULL) AS has_file,a.created_at,a.updated_at "
                + "FROM legacy_paper_archive a UNION ALL "
                + "SELECT p.id,p.title,p.reference_number,i.section_id,NULL::bigint,p.meeting_id,m.title,"
                + "'MEETING',(p.file_path IS NOT NULL),p.created_at,p.updated_at "
                + "FROM papers p JOIN meetings m ON m.id=p.meeting_id "
                + "JOIN agenda_items i ON i.id=p.agenda_item_id) x WHERE paper_id=?", id);
        return rows.isEmpty() ? ResponseEntity.notFound().build() : ResponseEntity.ok(rows.get(0));
    }

    @GetMapping("/{id}/comments")
    public List<Map<String, Object>> comments(@PathVariable long id) {
        return jdbc.queryForList("SELECT comment_id,created_by,comment_text,created_at FROM "
                + "(SELECT comment_id,paper_id,created_by,comment_text,created_at FROM legacy_archive_comments "
                + "UNION ALL SELECT id,paper_id,created_by,comment_text,created_at FROM comments "
                + "WHERE paper_id IS NOT NULL) x WHERE paper_id=? ORDER BY comment_id", id);
    }

    @GetMapping("/{id}/approval-comments")
    public List<Map<String, Object>> approvalComments(@PathVariable long id) {
        return jdbc.queryForList("SELECT user_id,comment_text FROM legacy_approval_comments "
                + "WHERE paper_id=? ORDER BY user_id", id);
    }

    @GetMapping("/{id}/decisions")
    public List<Map<String, Object>> decisions(@PathVariable long id, @RequestParam(defaultValue = "0") int page) {
        if (page < 0 || page > 100000) throw new IllegalArgumentException("Invalid page");
        return jdbc.queryForList("SELECT user_id,decision_status,notification_status,is_allowed,"
                + "ds_approval_status,approval_date,first_viewed,viewed_date FROM legacy_paper_decisions "
                + "WHERE paper_id=? ORDER BY user_id LIMIT 100 OFFSET ?", id, page * 100);
    }

    @GetMapping("/{id}/file")
    public ResponseEntity<Resource> file(@PathVariable long id) throws IOException {
        List<String> paths = jdbc.query("SELECT file_relative_path FROM legacy_paper_archive WHERE paper_id=?",
                (row, number) -> row.getString(1), id);
        String path = paths.isEmpty() ? null : paths.get(0);
        if (path == null) {
            List<String> urls = jdbc.query("SELECT file_path FROM papers WHERE id=?",
                    (row, number) -> row.getString(1), id);
            if (urls.isEmpty() || urls.get(0) == null) return ResponseEntity.notFound().build();
            String url = urls.get(0);
            String marker = "/api/files/content/";
            int at = url.lastIndexOf(marker);
            if (at < 0) return ResponseEntity.badRequest().build();
            try { path = new String(Base64.getUrlDecoder().decode(url.substring(at + marker.length())), StandardCharsets.UTF_8); }
            catch (IllegalArgumentException e) { return ResponseEntity.badRequest().build(); }
        }
        if (!path.matches("legacy-papers/" + id + "_[0-9]+\\.(pdf|pptx)"))
            return ResponseEntity.badRequest().build();
        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(path.getBytes(StandardCharsets.UTF_8));
        Resource resource = files.load(token, false);
        String contentType = path.endsWith(".pdf") ? "application/pdf"
                : "application/vnd.openxmlformats-officedocument.presentationml.presentation";
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=legacy-paper-" + id + path.substring(path.lastIndexOf('.')))
                .header("X-Content-Type-Options", "nosniff")
                .body(resource);
    }
}
