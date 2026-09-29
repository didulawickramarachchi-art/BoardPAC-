CREATE TABLE legacy_paper_archive (
    paper_id BIGINT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    reference_number VARCHAR(255),
    source_heading_id BIGINT,
    source_version_id BIGINT,
    source_doc_type INTEGER,
    file_relative_path VARCHAR(500),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX idx_legacy_paper_archive_title ON legacy_paper_archive(title);
