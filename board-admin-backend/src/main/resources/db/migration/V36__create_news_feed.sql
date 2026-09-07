CREATE TABLE news_posts (
    id BIGSERIAL PRIMARY KEY, title VARCHAR(300) NOT NULL, content VARCHAR(5000) NOT NULL,
    created_by BIGINT NOT NULL REFERENCES users(id), created_at TIMESTAMP NOT NULL, updated_at TIMESTAMP
);
CREATE TABLE news_comments (
    id BIGSERIAL PRIMARY KEY, post_id BIGINT NOT NULL REFERENCES news_posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id), message VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP NOT NULL, updated_at TIMESTAMP
);
CREATE TABLE news_reactions (
    id BIGSERIAL PRIMARY KEY, post_id BIGINT NOT NULL REFERENCES news_posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id), reaction_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL, updated_at TIMESTAMP, UNIQUE(post_id, user_id)
);
CREATE INDEX idx_news_comments_post ON news_comments(post_id);
CREATE INDEX idx_news_reactions_post ON news_reactions(post_id);
