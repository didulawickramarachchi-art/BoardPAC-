CREATE TABLE legacy_document_versions (
    version_id BIGINT PRIMARY KEY,
    previous_version_id BIGINT,
    source_file_path TEXT,
    created_by BIGINT,
    created_at TIMESTAMP,
    modified_by BIGINT,
    updated_at TIMESTAMP,
    info1 TEXT,
    info2 TEXT,
    info3 INTEGER
);

CREATE INDEX idx_legacy_document_versions_previous ON legacy_document_versions(previous_version_id);
