-- Add restaurant_id and order_ids to meal_plan_entries for linking eat-out entries to restaurants
-- This allows users to select a restaurant and specific orders when adding "Eat Out" to the meal plan

-- Add restaurant_id column (nullable - only used for eat out entries)
ALTER TABLE meal_plan_entries
ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES restaurants(id) ON DELETE SET NULL;

-- Add order_ids column (JSON array of order UUIDs that were selected for this meal)
-- This allows selecting multiple saved orders for a single eat-out meal
ALTER TABLE meal_plan_entries
ADD COLUMN IF NOT EXISTS order_ids JSONB DEFAULT '[]'::jsonb;

-- Create index for faster lookups by restaurant
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_restaurant_id ON meal_plan_entries(restaurant_id);

-- Note: When restaurant_id is set, eat_out_location can still be used as a fallback display
-- or for additional notes about the meal

COMMENT ON COLUMN meal_plan_entries.restaurant_id IS 'Reference to restaurant for eat-out entries';
COMMENT ON COLUMN meal_plan_entries.order_ids IS 'JSON array of restaurant order UUIDs selected for this meal';
