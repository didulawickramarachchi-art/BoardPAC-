-- Retry after a timed-out request could insert the same assignment twice.
-- Keep the oldest assignment for each user and subcategory.
DELETE FROM user_subcategory_access duplicate
USING user_subcategory_access original
WHERE duplicate.user_id = original.user_id
  AND duplicate.subcategory_id = original.subcategory_id
  AND duplicate.id > original.id;

ALTER TABLE user_subcategory_access
    ADD CONSTRAINT uq_user_subcategory_access_user_subcategory
    UNIQUE (user_id, subcategory_id);
