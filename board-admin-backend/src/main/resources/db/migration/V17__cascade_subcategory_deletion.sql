-- Deleting a subcategory removes its complete workflow tree:
-- privileges, shared-agenda mappings, meetings, and all meeting descendants
-- covered by V13's meeting-related cascade constraints.

ALTER TABLE user_subcategory_access
DROP CONSTRAINT IF EXISTS user_subcategory_access_subcategory_id_fkey;
ALTER TABLE user_subcategory_access
ADD CONSTRAINT user_subcategory_access_subcategory_id_fkey
FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE CASCADE;

ALTER TABLE shared_agenda_items
DROP CONSTRAINT IF EXISTS shared_agenda_items_source_subcategory_id_fkey;
ALTER TABLE shared_agenda_items
ADD CONSTRAINT shared_agenda_items_source_subcategory_id_fkey
FOREIGN KEY (source_subcategory_id) REFERENCES subcategories(id) ON DELETE CASCADE;

ALTER TABLE shared_agenda_items
DROP CONSTRAINT IF EXISTS shared_agenda_items_target_subcategory_id_fkey;
ALTER TABLE shared_agenda_items
ADD CONSTRAINT shared_agenda_items_target_subcategory_id_fkey
FOREIGN KEY (target_subcategory_id) REFERENCES subcategories(id) ON DELETE CASCADE;

ALTER TABLE meetings
DROP CONSTRAINT IF EXISTS meetings_subcategory_id_fkey;
ALTER TABLE meetings
ADD CONSTRAINT meetings_subcategory_id_fkey
FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE CASCADE;
