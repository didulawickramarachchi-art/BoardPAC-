CREATE TABLE legacy_paper_decisions (
    paper_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id),
    decision_status INTEGER,
    notification_status INTEGER,
    is_allowed INTEGER,
    ds_approval_status INTEGER,
    approval_date TIMESTAMP,
    first_viewed TIMESTAMP,
    viewed_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (paper_id, user_id)
);

CREATE INDEX idx_legacy_paper_decisions_user ON legacy_paper_decisions(user_id);
