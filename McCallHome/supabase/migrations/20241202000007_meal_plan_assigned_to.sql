-- =====================================================
-- Add Cooking Assignment to Meal Plan Entries
-- =====================================================
-- Allows assigning a household member as responsible for cooking each meal

ALTER TABLE meal_plan_entries
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES household_members(id) ON DELETE SET NULL;
