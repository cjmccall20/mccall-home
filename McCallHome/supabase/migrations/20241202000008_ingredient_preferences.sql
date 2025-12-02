-- =====================================================
-- Ingredient Preferences Table
-- =====================================================
-- Stores user preferences for ingredients including brand names,
-- preferred stores, and in-person shopping preferences

CREATE TABLE IF NOT EXISTS ingredient_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    canonical_name TEXT NOT NULL,  -- Normalized ingredient name (e.g., "soy sauce")
    display_name TEXT,             -- User's preferred brand/name (e.g., "Kikkoman Organic Soy Sauce")
    preferred_store TEXT,          -- Store enum value (walmart, costco, etc.)
    is_in_person BOOLEAN DEFAULT FALSE,  -- True if user prefers to select in person
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(household_id, canonical_name)
);

-- Index for fast lookups by household
CREATE INDEX IF NOT EXISTS idx_ingredient_preferences_household ON ingredient_preferences(household_id);

-- Index for searching by canonical name
CREATE INDEX IF NOT EXISTS idx_ingredient_preferences_name ON ingredient_preferences(canonical_name);

-- Enable RLS
ALTER TABLE ingredient_preferences ENABLE ROW LEVEL SECURITY;

-- Create permissive policy for development
DROP POLICY IF EXISTS "Allow all for ingredient_preferences" ON ingredient_preferences;
CREATE POLICY "Allow all for ingredient_preferences" ON ingredient_preferences FOR ALL USING (true) WITH CHECK (true);
