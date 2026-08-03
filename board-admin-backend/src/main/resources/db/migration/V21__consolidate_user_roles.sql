INSERT INTO roles (name, created_at, updated_at)
SELECT role_name, NOW(), NOW()
FROM (VALUES ('ADMIN'), ('SECRETARY'), ('MEMBER')) AS required_roles(role_name)
ON CONFLICT (name) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT DISTINCT ur.user_id, target.id
FROM user_roles ur
JOIN roles legacy ON legacy.id = ur.role_id
JOIN roles target ON target.name = CASE
    WHEN legacy.name IN ('SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM') THEN 'ADMIN'
    WHEN legacy.name = 'BOARD_SECRETARY' THEN 'SECRETARY'
    ELSE legacy.name
END
WHERE legacy.name IN ('SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM', 'BOARD_SECRETARY')
ON CONFLICT (user_id, role_id) DO NOTHING;

DELETE FROM user_roles
WHERE role_id IN (
    SELECT id FROM roles
    WHERE name IN ('SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM', 'BOARD_SECRETARY')
);

DELETE FROM roles
WHERE name IN ('SUPER_ADMIN', 'BOARD_ADMIN', 'SUPPORT_TEAM', 'BOARD_SECRETARY');
