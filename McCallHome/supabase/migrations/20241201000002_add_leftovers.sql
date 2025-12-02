-- =====================================================
-- Add Leftovers Support to Meal Plan Entries
-- =====================================================

-- Add is_leftovers column (boolean, default false)
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS is_leftovers BOOLEAN DEFAULT false;

-- Add leftovers_note column (optional text)
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS leftovers_note TEXT;

-- Create index for faster filtering if needed
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_is_leftovers ON meal_plan_entries(is_leftovers) WHERE is_leftovers = true;
