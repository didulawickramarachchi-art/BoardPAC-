CREATE TABLE legacy_audit_events (
    source_kind VARCHAR(20) NOT NULL,
    source_id BIGINT NOT NULL,
    event_number INTEGER,
    event_text TEXT,
    event_status TEXT,
    username TEXT,
    module_name TEXT,
    action_name TEXT,
    parameters TEXT,
    description TEXT,
    category_id BIGINT,
    subcategory_id BIGINT,
    meeting_id BIGINT,
    paper_id BIGINT,
    device_id BIGINT,
    created_by BIGINT,
    event_time TIMESTAMP,
    PRIMARY KEY (source_kind, source_id)
);

CREATE INDEX idx_legacy_audit_events_time ON legacy_audit_events(event_time DESC);
