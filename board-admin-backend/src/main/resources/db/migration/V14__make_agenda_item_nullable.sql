-- Make agenda_item_id nullable in papers table
-- Some papers may not have an associated agenda item
ALTER TABLE papers
ALTER COLUMN agenda_item_id DROP NOT NULL;
