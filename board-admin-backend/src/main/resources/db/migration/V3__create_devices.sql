CREATE TABLE IF NOT EXISTS devices (
    id BIGSERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL UNIQUE,
    device_info VARCHAR(255),
    board_pac_version VARCHAR(100),
    os_version VARCHAR(100),
    description VARCHAR(500),
    status VARCHAR(50),
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);