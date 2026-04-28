CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    salutation VARCHAR(50),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    board_email VARCHAR(255) NOT NULL UNIQUE,
    office_email VARCHAR(255),
    office_number VARCHAR(100),
    mobile_number VARCHAR(100),
    job_title VARCHAR(255),
    profile_picture_url VARCHAR(500),
    board_type VARCHAR(50),
    status VARCHAR(50),
    two_step_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id),
    role_id BIGINT NOT NULL REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);