CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_username VARCHAR(50) NOT NULL,
    user_display_name VARCHAR(100) NOT NULL,
    user_avatar_url VARCHAR(500),
    title VARCHAR(255),
    description TEXT,
    minio_key VARCHAR(500) NOT NULL,
    video_url VARCHAR(1000) NOT NULL,
    thumbnail_url VARCHAR(1000),
    duration_seconds INTEGER,
    views_count BIGINT DEFAULT 0,
    likes_count BIGINT DEFAULT 0,
    comments_count BIGINT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    icon_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE video_skills (
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES skills(id),
    PRIMARY KEY (video_id, skill_id)
);

CREATE TABLE hashtags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    video_count INT DEFAULT 0
);

CREATE TABLE video_hashtags (
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    hashtag_id UUID REFERENCES hashtags(id),
    PRIMARY KEY (video_id, hashtag_id)
);

CREATE TABLE video_likes (
    video_id UUID NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (video_id, user_id)
);

CREATE TABLE video_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES videos(id),
    reporter_user_id UUID NOT NULL,
    reason VARCHAR(500) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed default skills
INSERT INTO skills (name, icon_name) VALUES
    ('Dribbling', 'sports_soccer'),
    ('Shooting', 'target'),
    ('Passing', 'swap_horiz'),
    ('Defending', 'shield'),
    ('Freestyle', 'star'),
    ('Speed', 'flash_on'),
    ('Heading', 'sports_soccer'),
    ('First Touch', 'touch_app');

CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_created_at ON videos(created_at DESC);
CREATE INDEX idx_video_likes_user ON video_likes(user_id);
