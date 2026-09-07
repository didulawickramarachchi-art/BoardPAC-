ALTER TABLE news_posts ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0;
UPDATE news_posts SET display_order = id WHERE display_order = 0;
