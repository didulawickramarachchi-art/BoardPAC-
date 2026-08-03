CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message VARCHAR(3000) NOT NULL,
    type VARCHAR(255) NOT NULL,
    recipient_id BIGINT NOT NULL,
    created_by BIGINT,
    related_meeting_id BIGINT,
    related_paper_id BIGINT,
    related_comment_id BIGINT,
    related_attachment_id BIGINT,
    announcement BOOLEAN NOT NULL DEFAULT FALSE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_notifications_recipient
        FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_created_by
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created_at
    ON notifications (recipient_id, created_at DESC);
