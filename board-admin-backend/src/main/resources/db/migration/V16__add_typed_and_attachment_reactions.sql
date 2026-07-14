ALTER TABLE comment_reactions
    ADD COLUMN reaction_type VARCHAR(20) NOT NULL DEFAULT 'LIKE';

CREATE TABLE attachment_reactions (
    id BIGSERIAL PRIMARY KEY,
    attachment_id BIGINT NOT NULL REFERENCES paper_attachments(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reaction_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uk_attachment_reaction_user UNIQUE (attachment_id, user_id)
);

CREATE INDEX idx_attachment_reactions_attachment_id ON attachment_reactions(attachment_id);
