CREATE INDEX IF NOT EXISTS idx_news_posts_display_created
    ON news_posts (display_order DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_pack_deliveries_user_status
    ON pack_delivery (user_id, delivery_status);

CREATE INDEX IF NOT EXISTS idx_comment_shares_shared_to
    ON comment_shares (shared_to);

CREATE INDEX IF NOT EXISTS idx_paper_shares_shared_to
    ON paper_shares (shared_to);

CREATE INDEX IF NOT EXISTS idx_meeting_participants_user_meeting
    ON meeting_participants (user_id, meeting_id);

CREATE INDEX IF NOT EXISTS idx_meetings_subcategory_date
    ON meetings (subcategory_id, meeting_date_time);
