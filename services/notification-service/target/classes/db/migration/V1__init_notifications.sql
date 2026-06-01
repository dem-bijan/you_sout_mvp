CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    actor_id UUID NOT NULL,
    actor_username VARCHAR(50) NOT NULL,
    actor_avatar_url VARCHAR(500),
    reference_id UUID,
    reference_preview VARCHAR(200),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, created_at DESC);
