-- Add ON DELETE CASCADE to all meeting-related foreign keys
-- This allows meetings to be deleted along with all related data

-- Drop existing constraints for meeting_participants
ALTER TABLE meeting_participants 
DROP CONSTRAINT IF EXISTS meeting_participants_meeting_id_fkey;
ALTER TABLE meeting_participants 
ADD CONSTRAINT meeting_participants_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

-- Drop existing constraints for meeting_notes
ALTER TABLE meeting_notes 
DROP CONSTRAINT IF EXISTS meeting_notes_meeting_id_fkey;
ALTER TABLE meeting_notes 
ADD CONSTRAINT meeting_notes_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

-- Drop existing constraints for agenda_sections
ALTER TABLE agenda_sections 
DROP CONSTRAINT IF EXISTS agenda_sections_meeting_id_fkey;
ALTER TABLE agenda_sections 
ADD CONSTRAINT agenda_sections_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

-- Drop existing constraints for agenda_items
ALTER TABLE agenda_items 
DROP CONSTRAINT IF EXISTS agenda_items_meeting_id_fkey;
ALTER TABLE agenda_items 
ADD CONSTRAINT agenda_items_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

ALTER TABLE agenda_items 
DROP CONSTRAINT IF EXISTS agenda_items_section_id_fkey;
ALTER TABLE agenda_items 
ADD CONSTRAINT agenda_items_section_id_fkey 
FOREIGN KEY (section_id) REFERENCES agenda_sections(id) ON DELETE CASCADE;

-- Drop existing constraints for papers
ALTER TABLE papers 
DROP CONSTRAINT IF EXISTS papers_meeting_id_fkey;
ALTER TABLE papers 
ADD CONSTRAINT papers_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

ALTER TABLE papers 
DROP CONSTRAINT IF EXISTS papers_agenda_item_id_fkey;
ALTER TABLE papers 
ADD CONSTRAINT papers_agenda_item_id_fkey 
FOREIGN KEY (agenda_item_id) REFERENCES agenda_items(id) ON DELETE CASCADE;

-- Drop existing constraints for paper_approvals
ALTER TABLE paper_approvals 
DROP CONSTRAINT IF EXISTS paper_approvals_paper_id_fkey;
ALTER TABLE paper_approvals 
ADD CONSTRAINT paper_approvals_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for paper_shares
ALTER TABLE paper_shares 
DROP CONSTRAINT IF EXISTS paper_shares_paper_id_fkey;
ALTER TABLE paper_shares 
ADD CONSTRAINT paper_shares_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for paper_attachments
ALTER TABLE paper_attachments 
DROP CONSTRAINT IF EXISTS paper_attachments_paper_id_fkey;
ALTER TABLE paper_attachments 
ADD CONSTRAINT paper_attachments_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for comments
ALTER TABLE comments 
DROP CONSTRAINT IF EXISTS comments_meeting_id_fkey;
ALTER TABLE comments 
ADD CONSTRAINT comments_meeting_id_fkey 
FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE;

ALTER TABLE comments 
DROP CONSTRAINT IF EXISTS comments_paper_id_fkey;
ALTER TABLE comments 
ADD CONSTRAINT comments_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for comment_shares
ALTER TABLE comment_shares 
DROP CONSTRAINT IF EXISTS comment_shares_comment_id_fkey;
ALTER TABLE comment_shares 
ADD CONSTRAINT comment_shares_comment_id_fkey 
FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE;

-- Drop existing constraints for shared_agenda_items
ALTER TABLE shared_agenda_items 
DROP CONSTRAINT IF EXISTS shared_agenda_items_source_agenda_item_id_fkey;
ALTER TABLE shared_agenda_items 
ADD CONSTRAINT shared_agenda_items_source_agenda_item_id_fkey 
FOREIGN KEY (source_agenda_item_id) REFERENCES agenda_items(id) ON DELETE CASCADE;

-- Drop existing constraints for annotations
ALTER TABLE annotations 
DROP CONSTRAINT IF EXISTS annotations_paper_id_fkey;
ALTER TABLE annotations 
ADD CONSTRAINT annotations_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for pack_delivery
ALTER TABLE pack_delivery 
DROP CONSTRAINT IF EXISTS pack_delivery_paper_id_fkey;
ALTER TABLE pack_delivery 
ADD CONSTRAINT pack_delivery_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;

-- Drop existing constraints for file_access_logs
ALTER TABLE file_access_logs 
DROP CONSTRAINT IF EXISTS file_access_logs_paper_id_fkey;
ALTER TABLE file_access_logs 
ADD CONSTRAINT file_access_logs_paper_id_fkey 
FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE;
