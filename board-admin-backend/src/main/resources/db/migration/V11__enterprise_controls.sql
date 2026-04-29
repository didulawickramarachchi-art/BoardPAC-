CREATE TABLE IF NOT EXISTS annotations (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    annotation_type VARCHAR(100) NOT NULL,
    annotation_data_json VARCHAR(5000) NOT NULL,
    page_number INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS annotation_backups (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    backup_json TEXT NOT NULL,
    annotation_count INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    session_token VARCHAR(500) NOT NULL UNIQUE,
    access_channel VARCHAR(50) NOT NULL,
    device_info VARCHAR(500),
    ip_address VARCHAR(255),
    expires_at TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS file_access_logs (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT REFERENCES papers(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    action_name VARCHAR(100),
    file_name VARCHAR(255),
    action_time TIMESTAMP,
    channel VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);