-- =====================================================
-- Add Meal Category to Recipes
-- =====================================================
-- This allows recipes to be categorized by meal time
-- (breakfast, lunch, dinner, any) separately from dish type

ALTER TABLE recipes ADD COLUMN IF NOT EXISTS meal_category TEXT DEFAULT 'dinner';

-- Note: Valid values are 'breakfast', 'lunch', 'dinner', 'any'
-- Default is 'dinner' for existing recipes
