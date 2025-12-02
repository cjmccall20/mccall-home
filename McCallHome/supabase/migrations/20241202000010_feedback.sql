-- =====================================================
-- Feedback Table
-- =====================================================
-- Stores user feedback submissions for app improvements

CREATE TYPE feedback_type AS ENUM ('bug', 'feature', 'general', 'praise');
CREATE TYPE feedback_status AS ENUM ('new', 'reviewed', 'in_progress', 'resolved', 'wont_fix');

CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    -- Feedback content
    type feedback_type NOT NULL DEFAULT 'general',
    title TEXT NOT NULL,
    description TEXT NOT NULL,

    -- Context
    app_version TEXT,
    ios_version TEXT,
    device_model TEXT,
    screen_name TEXT,  -- Which screen the feedback was submitted from

    -- Admin fields
    status feedback_status DEFAULT 'new',
    admin_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
CREATE INDEX IF NOT EXISTS idx_feedback_created ON feedback(created_at DESC);

-- Enable RLS
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can view their own feedback
CREATE POLICY "Users can view their own feedback"
    ON feedback FOR SELECT
    USING (user_id = auth.uid());

-- Users can insert feedback
CREATE POLICY "Users can submit feedback"
    ON feedback FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users cannot update or delete feedback (admin only)
