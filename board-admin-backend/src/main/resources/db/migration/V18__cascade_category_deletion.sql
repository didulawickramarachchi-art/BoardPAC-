-- Deleting a category removes all of its subcategories and meetings.
-- V17 cascades each subcategory into privileges, shared agenda mappings, and
-- meetings; V13 cascades meetings into the complete workflow data tree.

ALTER TABLE subcategories
DROP CONSTRAINT IF EXISTS subcategories_category_id_fkey;
ALTER TABLE subcategories
ADD CONSTRAINT subcategories_category_id_fkey
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE;

ALTER TABLE meetings
DROP CONSTRAINT IF EXISTS meetings_category_id_fkey;
ALTER TABLE meetings
ADD CONSTRAINT meetings_category_id_fkey
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE;
