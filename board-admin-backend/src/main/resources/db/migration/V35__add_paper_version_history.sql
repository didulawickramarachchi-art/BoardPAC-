ALTER TABLE papers ADD COLUMN IF NOT EXISTS root_paper_id BIGINT REFERENCES papers(id);
ALTER TABLE papers ADD COLUMN IF NOT EXISTS current_version BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE papers ADD COLUMN IF NOT EXISTS revision_note VARCHAR(1000);
CREATE INDEX IF NOT EXISTS idx_papers_version_group ON papers(root_paper_id, version_number);
