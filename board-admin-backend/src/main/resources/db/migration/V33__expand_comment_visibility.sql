ALTER TABLE comments ADD COLUMN IF NOT EXISTS visibility VARCHAR(32) NOT NULL DEFAULT 'ALL_PARTICIPANTS';
ALTER TABLE comments ADD COLUMN IF NOT EXISTS page_number INTEGER;

CREATE TABLE IF NOT EXISTS comment_recipients (
    comment_id BIGINT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_recipients_user ON comment_recipients(user_id);
