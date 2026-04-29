INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'ENABLE_AGENDA_ITEM_SHARING_WITHIN_SUBCATEGORIES', 'true',
       'Enable agenda item sharing within subcategories', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_AGENDA_ITEM_SHARING_WITHIN_SUBCATEGORIES');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'ENABLE_CREATE_MEETINGS_WITH_PAST_DATES', 'false',
       'Allow creating meetings with past dates', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_CREATE_MEETINGS_WITH_PAST_DATES');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'MANDATORY_PAPER_REFERENCE_NUMBER', 'false',
       'Paper reference number is mandatory', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'MANDATORY_PAPER_REFERENCE_NUMBER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'UNIQUE_PAPER_REFERENCE_NUMBER', 'true',
       'Paper reference number must be unique', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'UNIQUE_PAPER_REFERENCE_NUMBER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'ENABLE_APPROVAL_COMMENTS_FOR_BOARD_MEMBER', 'true',
       'Allow board member approval comments', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_APPROVAL_COMMENTS_FOR_BOARD_MEMBER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_APPROVES_PAPER', 'false',
       'Send email when member approves paper', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_APPROVES_PAPER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'LEAD_TIME_PRIOR_TO_MEETING_DATE_EMAIL_ALERTS', '60',
       'Minutes before meeting to send pending approval alerts', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'LEAD_TIME_PRIOR_TO_MEETING_DATE_EMAIL_ALERTS');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'LEAD_TIME_PRIOR_TO_CIRCULAR_TARGET_DATE_EMAIL_ALERTS', '60',
       'Minutes before circular target date to send pending approval alerts', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'LEAD_TIME_PRIOR_TO_CIRCULAR_TARGET_DATE_EMAIL_ALERTS');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_COMMENT', 'false',
       'Send email when member shares a comment', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_COMMENT');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'MEETING_CIRCULAR', 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_ANNOTATED_PAPER', 'false',
       'Send email when member shares annotated paper', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'SEND_EMAIL_NOTIFICATION_WHEN_MEMBER_SHARES_ANNOTATED_PAPER');

INSERT INTO app_settings (setting_group, setting_key, setting_value, description, created_at, updated_at)
SELECT 'PAPER', 'ENABLE_PACK_DELIVERY_REPORT', 'true',
       'Enable pack delivery report', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE setting_key = 'ENABLE_PACK_DELIVERY_REPORT');