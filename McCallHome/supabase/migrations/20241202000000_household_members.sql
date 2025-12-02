-- Household Members Table
-- Tracks individual members of each household for task assignments, restaurant orders, etc.

CREATE TABLE IF NOT EXISTS household_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups by household
CREATE INDEX idx_household_members_household ON household_members(household_id);

-- RLS Policies
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their household members"
    ON household_members FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can manage their household members"
    ON household_members FOR ALL
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- Seed data for dev household
INSERT INTO household_members (household_id, name, email) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Cooper', 'cooper@mccall.home'),
    ('00000000-0000-0000-0000-000000000001', 'Ashlyn', 'ashlyn@mccall.home')
ON CONFLICT DO NOTHING;

-- Update restaurant_orders to reference household_member_id and add order name
ALTER TABLE restaurant_orders
    ADD COLUMN IF NOT EXISTS household_member_id UUID REFERENCES household_members(id),
    ADD COLUMN IF NOT EXISTS order_name TEXT;

-- Update honeydew_tasks to reference household_member for assignment
-- (assigned_to already exists, we'll use it to reference household_member_id)
