CREATE TABLE IF NOT EXISTS login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    username VARCHAR(255),
    ip_address VARCHAR(255),
    device_info VARCHAR(255),
    status VARCHAR(50),
    login_time TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    level VARCHAR(50),
    module_name VARCHAR(255),
    action_name VARCHAR(255),
    username VARCHAR(255),
    parameters VARCHAR(2000),
    device VARCHAR(255),
    action_time TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_group VARCHAR(100) NOT NULL,
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value VARCHAR(2000) NOT NULL,
    description VARCHAR(1000),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issue_reports (
    id BIGSERIAL PRIMARY KEY,
    issue_occurred_date DATE,
    issue_description VARCHAR(3000),
    username VARCHAR(255),
    screenshot_path VARCHAR(500),
    attach_log_files BOOLEAN,
    attach_product_settings BOOLEAN,
    attach_error_data BOOLEAN,
    other_resources VARCHAR(1000),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);