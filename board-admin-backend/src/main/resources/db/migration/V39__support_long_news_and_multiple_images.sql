ALTER TABLE news_posts ALTER COLUMN content TYPE TEXT;

CREATE TABLE news_post_images (
    post_id BIGINT NOT NULL REFERENCES news_posts(id) ON DELETE CASCADE,
    image_url VARCHAR(2048) NOT NULL,
    display_order INTEGER NOT NULL,
    PRIMARY KEY (post_id, display_order)
);

INSERT INTO news_post_images (post_id, image_url, display_order)
SELECT id, image_url, 0
FROM news_posts
WHERE image_url IS NOT NULL AND BTRIM(image_url) <> '';
