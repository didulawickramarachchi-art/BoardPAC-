CREATE TABLE IF NOT EXISTS meeting_action_items (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    description VARCHAR(2000),
    assignee_id BIGINT NOT NULL REFERENCES users(id),
    created_by BIGINT NOT NULL REFERENCES users(id),
    due_date DATE,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN',
    completion_note VARCHAR(2000),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_action_items_meeting ON meeting_action_items(meeting_id);
CREATE INDEX IF NOT EXISTS idx_action_items_assignee ON meeting_action_items(assignee_id);
