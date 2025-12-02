-- =====================================================
-- Household Settings Table
-- =====================================================
-- Stores household-level settings including calendar sync,
-- meal times, and email preferences

CREATE TABLE IF NOT EXISTS household_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL UNIQUE REFERENCES households(id) ON DELETE CASCADE,

    -- Calendar Integration
    google_calendar_enabled BOOLEAN DEFAULT FALSE,
    google_calendar_id TEXT,  -- The calendar ID to sync with
    google_refresh_token TEXT,  -- Encrypted OAuth refresh token
    sync_meals_to_calendar BOOLEAN DEFAULT FALSE,

    -- Default Meal Times (stored as HH:MM format)
    breakfast_time TEXT DEFAULT '08:00',
    lunch_time TEXT DEFAULT '12:00',
    dinner_time TEXT DEFAULT '18:00',

    -- Email Preferences
    morning_email_enabled BOOLEAN DEFAULT FALSE,
    morning_email_time TEXT DEFAULT '07:00',  -- When to send morning summary
    morning_email_recipients TEXT[],  -- Array of email addresses

    -- Timezone
    timezone TEXT DEFAULT 'America/New_York',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups by household
CREATE INDEX IF NOT EXISTS idx_household_settings_household ON household_settings(household_id);

-- Enable RLS
ALTER TABLE household_settings ENABLE ROW LEVEL SECURITY;

-- Users can view settings for their household
CREATE POLICY "Users can view their household settings"
    ON household_settings FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- Users can update settings for their household
CREATE POLICY "Users can update their household settings"
    ON household_settings FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- Users can insert settings for their household
CREATE POLICY "Users can insert their household settings"
    ON household_settings FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- Function to auto-create settings when household is created
CREATE OR REPLACE FUNCTION create_household_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO household_settings (household_id)
    VALUES (NEW.id)
    ON CONFLICT (household_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create settings on new household
DROP TRIGGER IF EXISTS on_household_created ON households;
CREATE TRIGGER on_household_created
    AFTER INSERT ON households
    FOR EACH ROW
    EXECUTE FUNCTION create_household_settings();

-- Create settings for existing households
INSERT INTO household_settings (household_id)
SELECT id FROM households
WHERE id NOT IN (SELECT household_id FROM household_settings)
ON CONFLICT (household_id) DO NOTHING;
