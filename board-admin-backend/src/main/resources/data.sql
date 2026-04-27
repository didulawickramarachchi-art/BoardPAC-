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