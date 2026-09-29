CREATE TABLE legacy_archive_comments (
    comment_id BIGINT PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES legacy_paper_archive(paper_id),
    created_by BIGINT NOT NULL REFERENCES users(id),
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP
);

CREATE TABLE legacy_approval_comments (
    paper_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id),
    comment_text TEXT NOT NULL,
    PRIMARY KEY (paper_id, user_id)
);
