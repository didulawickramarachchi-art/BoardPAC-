ALTER TABLE users
    ADD COLUMN IF NOT EXISTS access_profile VARCHAR(50);

UPDATE users u
SET access_profile = CASE
    WHEN EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = u.id AND r.name = 'ADMIN'
    ) THEN 'BOARD_ADMINISTRATOR'
    WHEN EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = u.id AND r.name = 'SECRETARY'
    ) THEN 'BOARD_SECRETARY'
    ELSE 'MEMBER'
END
WHERE access_profile IS NULL;

ALTER TABLE users
    ALTER COLUMN access_profile SET NOT NULL;
