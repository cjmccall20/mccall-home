-- =====================================================
-- Allow Multiple Dishes Per Meal Slot
-- =====================================================
-- Drop the unique constraint that prevents adding multiple dishes
-- to the same meal slot (household_id, date, meal_type)

ALTER TABLE meal_plan_entries DROP CONSTRAINT IF EXISTS meal_plan_entries_household_date_meal_unique;

-- Note: This allows users to add multiple recipes/items to a single meal
-- (e.g., main dish + side dish for dinner)
