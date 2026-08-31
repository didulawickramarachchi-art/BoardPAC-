CREATE TABLE user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    favorite_type VARCHAR(20) NOT NULL,
    target_id BIGINT NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uk_user_favorite UNIQUE (user_id, favorite_type, target_id),
    CONSTRAINT ck_user_favorite_type CHECK (favorite_type IN ('MEETING', 'PAPER'))
);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
