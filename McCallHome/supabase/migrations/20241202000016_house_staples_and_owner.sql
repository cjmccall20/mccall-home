-- =====================================================
-- House Staples Table
-- Items that automatically appear on every grocery list
-- =====================================================

CREATE TABLE IF NOT EXISTS house_staples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity TEXT,  -- e.g., "2", "1 gallon", "1 box"
    category TEXT DEFAULT 'Other',
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE house_staples ENABLE ROW LEVEL SECURITY;

-- RLS Policies for house_staples
CREATE POLICY "house_staples_select" ON house_staples FOR SELECT USING (
    household_id = '00000000-0000-0000-0000-000000000001'::uuid
    OR household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
);

CREATE POLICY "house_staples_insert" ON house_staples FOR INSERT WITH CHECK (
    household_id = '00000000-0000-0000-0000-000000000001'::uuid
    OR household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
);

CREATE POLICY "house_staples_update" ON house_staples FOR UPDATE USING (
    household_id = '00000000-0000-0000-0000-000000000001'::uuid
    OR household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
);

CREATE POLICY "house_staples_delete" ON house_staples FOR DELETE USING (
    household_id = '00000000-0000-0000-0000-000000000001'::uuid
    OR household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
);

-- Index for faster queries
CREATE INDEX idx_house_staples_household ON house_staples(household_id);

-- =====================================================
-- Add owner field to household_members
-- =====================================================

ALTER TABLE household_members
ADD COLUMN IF NOT EXISTS is_owner BOOLEAN DEFAULT false;

-- Set the first member (or dev user) as owner
UPDATE household_members
SET is_owner = true
WHERE household_id = '00000000-0000-0000-0000-000000000001'::uuid
AND id = (
    SELECT id FROM household_members
    WHERE household_id = '00000000-0000-0000-0000-000000000001'::uuid
    ORDER BY created_at ASC
    LIMIT 1
);

-- =====================================================
-- Update trigger for updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_house_staples_updated_at ON house_staples;
CREATE TRIGGER update_house_staples_updated_at
    BEFORE UPDATE ON house_staples
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
