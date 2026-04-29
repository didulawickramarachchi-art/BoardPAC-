INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'WATERMARK_TYPE', 'USER_NAME',
       'Watermark type for paper display/print', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'WATERMARK_TYPE');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'DISCLAIMER_MESSAGE_WHEN_EMAILING_OR_PRINTING_AGENDA_ITEM',
       'Confidential board material. Unauthorized distribution is prohibited.',
       'Disclaimer message for email/print', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'DISCLAIMER_MESSAGE_WHEN_EMAILING_OR_PRINTING_AGENDA_ITEM');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'USER_MANAGEMENT', 'ENABLE_ANNOTATION_BACKUP_RESTORE', 'true',
       'Enable annotation backup and restore', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_ANNOTATION_BACKUP_RESTORE');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_MEMBERS', 'false',
       'Allow board members to print papers', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_MEMBERS');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_SECRETARY', 'true',
       'Allow board secretary to print papers', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_PAPER_PRINTING_OPTION_FOR_BOARD_SECRETARY');