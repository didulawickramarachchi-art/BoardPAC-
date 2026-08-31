CREATE TABLE paper_read_states (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_opened_at TIMESTAMP NOT NULL,
    last_opened_at TIMESTAMP NOT NULL,
    last_page INTEGER NOT NULL DEFAULT 1,
    total_pages INTEGER,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uk_paper_read_state_user_paper UNIQUE (paper_id, user_id)
);

CREATE INDEX idx_paper_read_states_user ON paper_read_states(user_id);
