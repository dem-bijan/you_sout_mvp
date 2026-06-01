CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL,
    user_id UUID NOT NULL,
    user_username VARCHAR(50) NOT NULL,
    user_display_name VARCHAR(100) NOT NULL,
    user_avatar_url VARCHAR(500),
    content TEXT NOT NULL,
    parent_id UUID REFERENCES comments(id),
    likes_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_comments_video_id ON comments(video_id, created_at DESC);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);
