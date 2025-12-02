-- =====================================================
-- Calendar Events Table
-- =====================================================
-- Stores synced calendar events for morning email
-- and local caching of Google Calendar data

CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    -- External calendar reference
    google_event_id TEXT,
    google_calendar_id TEXT,

    -- Event details
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,

    -- Timing
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    all_day BOOLEAN DEFAULT FALSE,

    -- Recurrence
    recurring_event_id TEXT,  -- Parent event ID for recurring events

    -- Source tracking
    source TEXT DEFAULT 'google',  -- 'google', 'manual', 'meal_plan'
    meal_plan_entry_id UUID REFERENCES meal_plan_entries(id) ON DELETE SET NULL,

    -- Sync metadata
    last_synced_at TIMESTAMPTZ DEFAULT NOW(),
    etag TEXT,  -- For Google Calendar sync optimization

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent duplicates from Google
    UNIQUE(household_id, google_event_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_calendar_events_household ON calendar_events(household_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start ON calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_date_range ON calendar_events(household_id, start_time, end_time);

-- Enable RLS
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their household calendar events"
    ON calendar_events FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create calendar events"
    ON calendar_events FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household calendar events"
    ON calendar_events FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household calendar events"
    ON calendar_events FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));
