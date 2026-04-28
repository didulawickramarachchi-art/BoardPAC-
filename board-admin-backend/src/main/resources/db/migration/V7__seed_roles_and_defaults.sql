INSERT INTO roles (name, created_at, updated_at)
SELECT 'SUPER_ADMIN', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'SUPER_ADMIN');

INSERT INTO roles (name, created_at, updated_at)
SELECT 'BOARD_ADMIN', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'BOARD_ADMIN');

INSERT INTO roles (name, created_at, updated_at)
SELECT 'BOARD_SECRETARY', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'BOARD_SECRETARY');

INSERT INTO roles (name, created_at, updated_at)
SELECT 'SUPPORT_TEAM', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'SUPPORT_TEAM');

INSERT INTO roles (name, created_at, updated_at)
SELECT 'MEMBER', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'MEMBER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'USER_MANAGEMENT', 'ENABLE_2_STEP_AUTH', 'true', 'Enable two-step authentication', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_2_STEP_AUTH');