CREATE TABLE IF NOT EXISTS shared_agenda_items (
    id BIGSERIAL PRIMARY KEY,
    source_agenda_item_id BIGINT NOT NULL REFERENCES agenda_items(id),
    source_subcategory_id BIGINT NOT NULL REFERENCES subcategories(id),
    target_subcategory_id BIGINT NOT NULL REFERENCES subcategories(id),
    shared_by BIGINT NOT NULL REFERENCES users(id),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paper_attachments (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    display_order INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);