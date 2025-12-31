-- =====================================================
-- Fix Infinite Recursion in Users Policy
-- =====================================================
-- The users_select policy was causing infinite recursion
-- because it queried the users table from within its own policy.
--
-- Solution: Create a security definer function that bypasses RLS
-- to get the current user's household_id.

-- Step 1: Create a function to get current user's household_id
-- This runs with elevated privileges (security definer) so it
-- bypasses RLS and won't cause recursion.
CREATE OR REPLACE FUNCTION get_my_household_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT household_id FROM users WHERE id = auth.uid()
$$;

-- Step 2: Drop the problematic users policies
DROP POLICY IF EXISTS "users_select" ON users;
DROP POLICY IF EXISTS "users_update" ON users;
DROP POLICY IF EXISTS "users_insert" ON users;

-- Step 3: Recreate users policies using the function
CREATE POLICY "users_select" ON users FOR SELECT
    USING (
        id = (select auth.uid())
        OR household_id = get_my_household_id()
    );

CREATE POLICY "users_update" ON users FOR UPDATE
    USING (id = (select auth.uid()));

CREATE POLICY "users_insert" ON users FOR INSERT
    WITH CHECK (id = (select auth.uid()));

-- Step 4: Also fix households policy (same issue)
DROP POLICY IF EXISTS "households_select" ON households;
DROP POLICY IF EXISTS "households_update" ON households;
DROP POLICY IF EXISTS "households_insert" ON households;

CREATE POLICY "households_select" ON households FOR SELECT
    USING (id = get_my_household_id());

CREATE POLICY "households_update" ON households FOR UPDATE
    USING (id = get_my_household_id());

CREATE POLICY "households_insert" ON households FOR INSERT
    WITH CHECK (true);  -- Allow creation during signup

-- Step 5: Fix all other policies that reference users table
-- These were using: SELECT household_id FROM users WHERE id = auth.uid()
-- Now use: get_my_household_id()

-- Recipes
DROP POLICY IF EXISTS "recipes_select" ON recipes;
DROP POLICY IF EXISTS "recipes_insert" ON recipes;
DROP POLICY IF EXISTS "recipes_update" ON recipes;
DROP POLICY IF EXISTS "recipes_delete" ON recipes;

CREATE POLICY "recipes_select" ON recipes FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "recipes_insert" ON recipes FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "recipes_update" ON recipes FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "recipes_delete" ON recipes FOR DELETE
    USING (household_id = get_my_household_id());

-- Meal Plan Entries
DROP POLICY IF EXISTS "meal_plan_entries_select" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_insert" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_update" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_delete" ON meal_plan_entries;

CREATE POLICY "meal_plan_entries_select" ON meal_plan_entries FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_entries_insert" ON meal_plan_entries FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "meal_plan_entries_update" ON meal_plan_entries FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_entries_delete" ON meal_plan_entries FOR DELETE
    USING (household_id = get_my_household_id());

-- Grocery Lists
DROP POLICY IF EXISTS "grocery_lists_select" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_insert" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_update" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_delete" ON grocery_lists;

CREATE POLICY "grocery_lists_select" ON grocery_lists FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "grocery_lists_insert" ON grocery_lists FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "grocery_lists_update" ON grocery_lists FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "grocery_lists_delete" ON grocery_lists FOR DELETE
    USING (household_id = get_my_household_id());

-- Grocery Items (references grocery_lists, not users directly)
DROP POLICY IF EXISTS "grocery_items_select" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_insert" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_update" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_delete" ON grocery_items;

CREATE POLICY "grocery_items_select" ON grocery_items FOR SELECT
    USING (grocery_list_id IN (
        SELECT id FROM grocery_lists WHERE household_id = get_my_household_id()
    ));

CREATE POLICY "grocery_items_insert" ON grocery_items FOR INSERT
    WITH CHECK (grocery_list_id IN (
        SELECT id FROM grocery_lists WHERE household_id = get_my_household_id()
    ));

CREATE POLICY "grocery_items_update" ON grocery_items FOR UPDATE
    USING (grocery_list_id IN (
        SELECT id FROM grocery_lists WHERE household_id = get_my_household_id()
    ));

CREATE POLICY "grocery_items_delete" ON grocery_items FOR DELETE
    USING (grocery_list_id IN (
        SELECT id FROM grocery_lists WHERE household_id = get_my_household_id()
    ));

-- Previous Grocery Items
DROP POLICY IF EXISTS "previous_grocery_items_select" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_insert" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_update" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_delete" ON previous_grocery_items;

CREATE POLICY "previous_grocery_items_select" ON previous_grocery_items FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "previous_grocery_items_insert" ON previous_grocery_items FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "previous_grocery_items_update" ON previous_grocery_items FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "previous_grocery_items_delete" ON previous_grocery_items FOR DELETE
    USING (household_id = get_my_household_id());

-- Honeydew Tasks
DROP POLICY IF EXISTS "honeydew_tasks_select" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_insert" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_update" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_delete" ON honeydew_tasks;

CREATE POLICY "honeydew_tasks_select" ON honeydew_tasks FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_insert" ON honeydew_tasks FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_update" ON honeydew_tasks FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_delete" ON honeydew_tasks FOR DELETE
    USING (household_id = get_my_household_id());

-- Restaurants
DROP POLICY IF EXISTS "restaurants_select" ON restaurants;
DROP POLICY IF EXISTS "restaurants_insert" ON restaurants;
DROP POLICY IF EXISTS "restaurants_update" ON restaurants;
DROP POLICY IF EXISTS "restaurants_delete" ON restaurants;

CREATE POLICY "restaurants_select" ON restaurants FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "restaurants_insert" ON restaurants FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "restaurants_update" ON restaurants FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "restaurants_delete" ON restaurants FOR DELETE
    USING (household_id = get_my_household_id());

-- Restaurant Orders
DROP POLICY IF EXISTS "restaurant_orders_select" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_insert" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_update" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_delete" ON restaurant_orders;

CREATE POLICY "restaurant_orders_select" ON restaurant_orders FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "restaurant_orders_insert" ON restaurant_orders FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "restaurant_orders_update" ON restaurant_orders FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "restaurant_orders_delete" ON restaurant_orders FOR DELETE
    USING (household_id = get_my_household_id());

-- Household Members
DROP POLICY IF EXISTS "household_members_select" ON household_members;
DROP POLICY IF EXISTS "household_members_insert" ON household_members;
DROP POLICY IF EXISTS "household_members_update" ON household_members;
DROP POLICY IF EXISTS "household_members_delete" ON household_members;

CREATE POLICY "household_members_select" ON household_members FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "household_members_insert" ON household_members FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "household_members_update" ON household_members FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "household_members_delete" ON household_members FOR DELETE
    USING (household_id = get_my_household_id());

-- Ingredient Preferences
DROP POLICY IF EXISTS "ingredient_preferences_select" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_insert" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_update" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_delete" ON ingredient_preferences;

CREATE POLICY "ingredient_preferences_select" ON ingredient_preferences FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "ingredient_preferences_insert" ON ingredient_preferences FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "ingredient_preferences_update" ON ingredient_preferences FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "ingredient_preferences_delete" ON ingredient_preferences FOR DELETE
    USING (household_id = get_my_household_id());

-- Pantry Staples
DROP POLICY IF EXISTS "pantry_staples_select" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_insert" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_update" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_delete" ON pantry_staples;

CREATE POLICY "pantry_staples_select" ON pantry_staples FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "pantry_staples_insert" ON pantry_staples FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "pantry_staples_update" ON pantry_staples FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "pantry_staples_delete" ON pantry_staples FOR DELETE
    USING (household_id = get_my_household_id());

-- Household Settings
DROP POLICY IF EXISTS "household_settings_select" ON household_settings;
DROP POLICY IF EXISTS "household_settings_insert" ON household_settings;
DROP POLICY IF EXISTS "household_settings_update" ON household_settings;

CREATE POLICY "household_settings_select" ON household_settings FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "household_settings_insert" ON household_settings FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "household_settings_update" ON household_settings FOR UPDATE
    USING (household_id = get_my_household_id());

-- Calendar Events
DROP POLICY IF EXISTS "calendar_events_select" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_insert" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_update" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_delete" ON calendar_events;

CREATE POLICY "calendar_events_select" ON calendar_events FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "calendar_events_insert" ON calendar_events FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "calendar_events_update" ON calendar_events FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "calendar_events_delete" ON calendar_events FOR DELETE
    USING (household_id = get_my_household_id());

-- House Staples
DROP POLICY IF EXISTS "house_staples_select" ON house_staples;
DROP POLICY IF EXISTS "house_staples_insert" ON house_staples;
DROP POLICY IF EXISTS "house_staples_update" ON house_staples;
DROP POLICY IF EXISTS "house_staples_delete" ON house_staples;

CREATE POLICY "house_staples_select" ON house_staples FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "house_staples_insert" ON house_staples FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "house_staples_update" ON house_staples FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "house_staples_delete" ON house_staples FOR DELETE
    USING (household_id = get_my_household_id());

-- Recipe Ratings
DROP POLICY IF EXISTS "recipe_ratings_select" ON recipe_ratings;
DROP POLICY IF EXISTS "recipe_ratings_insert" ON recipe_ratings;
DROP POLICY IF EXISTS "recipe_ratings_update" ON recipe_ratings;
DROP POLICY IF EXISTS "recipe_ratings_delete" ON recipe_ratings;

CREATE POLICY "recipe_ratings_select" ON recipe_ratings FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "recipe_ratings_insert" ON recipe_ratings FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "recipe_ratings_update" ON recipe_ratings FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "recipe_ratings_delete" ON recipe_ratings FOR DELETE
    USING (household_id = get_my_household_id());

-- Meal Plan Templates
DROP POLICY IF EXISTS "meal_plan_templates_select" ON meal_plan_templates;
DROP POLICY IF EXISTS "meal_plan_templates_insert" ON meal_plan_templates;
DROP POLICY IF EXISTS "meal_plan_templates_update" ON meal_plan_templates;
DROP POLICY IF EXISTS "meal_plan_templates_delete" ON meal_plan_templates;

CREATE POLICY "meal_plan_templates_select" ON meal_plan_templates FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_templates_insert" ON meal_plan_templates FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "meal_plan_templates_update" ON meal_plan_templates FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_templates_delete" ON meal_plan_templates FOR DELETE
    USING (household_id = get_my_household_id());

-- Meal Plan Rotations
DROP POLICY IF EXISTS "meal_plan_rotations_select" ON meal_plan_rotations;
DROP POLICY IF EXISTS "meal_plan_rotations_insert" ON meal_plan_rotations;
DROP POLICY IF EXISTS "meal_plan_rotations_update" ON meal_plan_rotations;
DROP POLICY IF EXISTS "meal_plan_rotations_delete" ON meal_plan_rotations;

CREATE POLICY "meal_plan_rotations_select" ON meal_plan_rotations FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_rotations_insert" ON meal_plan_rotations FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "meal_plan_rotations_update" ON meal_plan_rotations FOR UPDATE
    USING (household_id = get_my_household_id());

CREATE POLICY "meal_plan_rotations_delete" ON meal_plan_rotations FOR DELETE
    USING (household_id = get_my_household_id());

-- Household Invitations (special case - needs token lookup too)
DROP POLICY IF EXISTS "household_invitations_select" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_insert" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_update" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_delete" ON household_invitations;

CREATE POLICY "household_invitations_select" ON household_invitations FOR SELECT
    USING (
        household_id = get_my_household_id()
        OR true  -- Allow lookup by token for accepting (token checked in app logic)
    );

CREATE POLICY "household_invitations_insert" ON household_invitations FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "household_invitations_update" ON household_invitations FOR UPDATE
    USING (
        household_id = get_my_household_id()
        OR true  -- Allow updating when accepting by token
    );

CREATE POLICY "household_invitations_delete" ON household_invitations FOR DELETE
    USING (household_id = get_my_household_id());

-- Feedback (user-specific, not household)
-- Already correct, no changes needed

-- Google Tokens (user-specific, not household)
-- Already correct, no changes needed
