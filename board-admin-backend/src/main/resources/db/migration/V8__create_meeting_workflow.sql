CREATE TABLE IF NOT EXISTS meetings (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    meeting_date_time TIMESTAMP NOT NULL,
    target_date_time TIMESTAMP,
    location VARCHAR(255),
    description VARCHAR(3000),
    category_id BIGINT NOT NULL REFERENCES categories(id),
    subcategory_id BIGINT NOT NULL REFERENCES subcategories(id),
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS meeting_participants (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    participant_status VARCHAR(50) NOT NULL,
    status_reason VARCHAR(1000),
    display_sequence INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uq_meeting_user UNIQUE (meeting_id, user_id)
);

CREATE TABLE IF NOT EXISTS meeting_notes (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    note_text VARCHAR(5000) NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS agenda_sections (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id),
    title VARCHAR(255) NOT NULL,
    number_label VARCHAR(100),
    display_order INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS agenda_items (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id),
    section_id BIGINT REFERENCES agenda_sections(id),
    item_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    number_label VARCHAR(100),
    display_order INT,
    description VARCHAR(3000),
    media_path VARCHAR(500),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS papers (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT NOT NULL REFERENCES meetings(id),
    agenda_item_id BIGINT NOT NULL REFERENCES agenda_items(id),
    paper_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    reference_number VARCHAR(255),
    file_path VARCHAR(500),
    file_name VARCHAR(255),
    version_number INT,
    requires_approval BOOLEAN DEFAULT FALSE,
    is_main_paper BOOLEAN DEFAULT TRUE,
    disclaimer_message VARCHAR(2000),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paper_approvals (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    approval_status VARCHAR(50) NOT NULL,
    approval_comment VARCHAR(2000),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uq_paper_user UNIQUE (paper_id, user_id)
);

CREATE TABLE IF NOT EXISTS comments (
    id BIGSERIAL PRIMARY KEY,
    meeting_id BIGINT REFERENCES meetings(id),
    paper_id BIGINT REFERENCES papers(id),
    created_by BIGINT NOT NULL REFERENCES users(id),
    comment_text VARCHAR(4000) NOT NULL,
    annotated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS comment_shares (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT NOT NULL REFERENCES comments(id),
    shared_by BIGINT NOT NULL REFERENCES users(id),
    shared_to BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paper_shares (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id),
    shared_by BIGINT NOT NULL REFERENCES users(id),
    shared_to BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pack_delivery (
    id BIGSERIAL PRIMARY KEY,
    paper_id BIGINT NOT NULL REFERENCES papers(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    delivery_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uq_packdelivery_paper_user UNIQUE (paper_id, user_id)
);