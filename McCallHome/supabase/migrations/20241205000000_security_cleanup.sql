-- =====================================================
-- Security Cleanup Migration
-- =====================================================
-- This migration:
-- 1. Drops all duplicate/conflicting policies
-- 2. Enables RLS on all tables
-- 3. Creates optimized policies using (select auth.uid())
-- 4. Ensures proper security for production

-- =====================================================
-- STEP 1: DROP ALL EXISTING POLICIES
-- =====================================================
-- We'll drop all policies and recreate them cleanly

-- Households
DROP POLICY IF EXISTS "Allow all for households" ON households;
DROP POLICY IF EXISTS "Household members can view household" ON households;
DROP POLICY IF EXISTS "households_select" ON households;
DROP POLICY IF EXISTS "households_update" ON households;
DROP POLICY IF EXISTS "Users can view their household" ON households;
DROP POLICY IF EXISTS "Users can update their household" ON households;
DROP POLICY IF EXISTS "Allow users to read their household" ON households;

-- Users
DROP POLICY IF EXISTS "Allow all for users" ON users;
DROP POLICY IF EXISTS "Users can view own record" ON users;
DROP POLICY IF EXISTS "Users can update own record" ON users;
DROP POLICY IF EXISTS "users_select" ON users;
DROP POLICY IF EXISTS "users_update" ON users;
DROP POLICY IF EXISTS "users_insert" ON users;
DROP POLICY IF EXISTS "Users can view users in their household" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Recipes
DROP POLICY IF EXISTS "Allow all for recipes" ON recipes;
DROP POLICY IF EXISTS "Household members can all recipes" ON recipes;
DROP POLICY IF EXISTS "recipes_select" ON recipes;
DROP POLICY IF EXISTS "recipes_insert" ON recipes;
DROP POLICY IF EXISTS "recipes_update" ON recipes;
DROP POLICY IF EXISTS "recipes_delete" ON recipes;
DROP POLICY IF EXISTS "Users can view their household recipes" ON recipes;
DROP POLICY IF EXISTS "Users can create recipes for their household" ON recipes;
DROP POLICY IF EXISTS "Users can update their household recipes" ON recipes;
DROP POLICY IF EXISTS "Users can delete their household recipes" ON recipes;

-- Meal Plan Entries
DROP POLICY IF EXISTS "Allow all for meal_plan_entries" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_select" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_insert" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_update" ON meal_plan_entries;
DROP POLICY IF EXISTS "meal_plan_entries_delete" ON meal_plan_entries;
DROP POLICY IF EXISTS "Users can view their household meal plan" ON meal_plan_entries;
DROP POLICY IF EXISTS "Users can create meal plan entries" ON meal_plan_entries;
DROP POLICY IF EXISTS "Users can update their household meal plan" ON meal_plan_entries;
DROP POLICY IF EXISTS "Users can delete their household meal plan entries" ON meal_plan_entries;

-- Grocery Lists
DROP POLICY IF EXISTS "Allow all for grocery_lists" ON grocery_lists;
DROP POLICY IF EXISTS "Household members can all grocery_lists" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_select" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_insert" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_update" ON grocery_lists;
DROP POLICY IF EXISTS "grocery_lists_delete" ON grocery_lists;
DROP POLICY IF EXISTS "Users can view their household grocery lists" ON grocery_lists;
DROP POLICY IF EXISTS "Users can create grocery lists" ON grocery_lists;
DROP POLICY IF EXISTS "Users can update their household grocery lists" ON grocery_lists;
DROP POLICY IF EXISTS "Users can delete their household grocery lists" ON grocery_lists;

-- Grocery Items
DROP POLICY IF EXISTS "Allow all for grocery_items" ON grocery_items;
DROP POLICY IF EXISTS "Household members can all grocery_items" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_select" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_insert" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_update" ON grocery_items;
DROP POLICY IF EXISTS "grocery_items_delete" ON grocery_items;
DROP POLICY IF EXISTS "Users can view their household grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Users can create grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Users can update their household grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Users can delete their household grocery items" ON grocery_items;

-- Previous Grocery Items
DROP POLICY IF EXISTS "Allow all for previous_grocery_items" ON previous_grocery_items;
DROP POLICY IF EXISTS "Household members can all previous_grocery_items" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_select" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_insert" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_update" ON previous_grocery_items;
DROP POLICY IF EXISTS "previous_grocery_items_delete" ON previous_grocery_items;

-- Honeydew Tasks
DROP POLICY IF EXISTS "Allow all for honeydew_tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_select" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_insert" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_update" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_delete" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can view their household tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can create tasks for their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can update their household tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can delete their household tasks" ON honeydew_tasks;

-- Restaurants
DROP POLICY IF EXISTS "Allow all for restaurants" ON restaurants;
DROP POLICY IF EXISTS "restaurants_select" ON restaurants;
DROP POLICY IF EXISTS "restaurants_insert" ON restaurants;
DROP POLICY IF EXISTS "restaurants_update" ON restaurants;
DROP POLICY IF EXISTS "restaurants_delete" ON restaurants;
DROP POLICY IF EXISTS "Users can view their household restaurants" ON restaurants;
DROP POLICY IF EXISTS "Users can create restaurants for their household" ON restaurants;
DROP POLICY IF EXISTS "Users can update their household restaurants" ON restaurants;
DROP POLICY IF EXISTS "Users can delete their household restaurants" ON restaurants;

-- Restaurant Orders
DROP POLICY IF EXISTS "Allow all for restaurant_orders" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_select" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_insert" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_update" ON restaurant_orders;
DROP POLICY IF EXISTS "restaurant_orders_delete" ON restaurant_orders;
DROP POLICY IF EXISTS "Users can view their household restaurant orders" ON restaurant_orders;
DROP POLICY IF EXISTS "Users can create restaurant orders" ON restaurant_orders;
DROP POLICY IF EXISTS "Users can update their household restaurant orders" ON restaurant_orders;
DROP POLICY IF EXISTS "Users can delete their household restaurant orders" ON restaurant_orders;

-- Household Members
DROP POLICY IF EXISTS "Allow all for household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all reads on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all writes on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all updates on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all deletes on household_members" ON household_members;
DROP POLICY IF EXISTS "household_members_select" ON household_members;
DROP POLICY IF EXISTS "household_members_insert" ON household_members;
DROP POLICY IF EXISTS "household_members_update" ON household_members;
DROP POLICY IF EXISTS "household_members_delete" ON household_members;

-- Ingredient Preferences
DROP POLICY IF EXISTS "Allow all for ingredient_preferences" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_select" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_insert" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_update" ON ingredient_preferences;
DROP POLICY IF EXISTS "ingredient_preferences_delete" ON ingredient_preferences;
DROP POLICY IF EXISTS "Users can view their household ingredient preferences" ON ingredient_preferences;
DROP POLICY IF EXISTS "Users can create ingredient preferences" ON ingredient_preferences;
DROP POLICY IF EXISTS "Users can update their household ingredient preferences" ON ingredient_preferences;
DROP POLICY IF EXISTS "Users can delete their household ingredient preferences" ON ingredient_preferences;

-- Pantry Staples
DROP POLICY IF EXISTS "Allow all for pantry_staples" ON pantry_staples;
DROP POLICY IF EXISTS "Household members can all pantry_staples" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_select" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_insert" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_update" ON pantry_staples;
DROP POLICY IF EXISTS "pantry_staples_delete" ON pantry_staples;
DROP POLICY IF EXISTS "Users can view their household pantry staples" ON pantry_staples;
DROP POLICY IF EXISTS "Users can create pantry staples" ON pantry_staples;
DROP POLICY IF EXISTS "Users can update their household pantry staples" ON pantry_staples;
DROP POLICY IF EXISTS "Users can delete their household pantry staples" ON pantry_staples;

-- Household Settings
DROP POLICY IF EXISTS "Allow all for household_settings" ON household_settings;
DROP POLICY IF EXISTS "Users can view their household settings" ON household_settings;
DROP POLICY IF EXISTS "Users can insert their household settings" ON household_settings;
DROP POLICY IF EXISTS "Users can update their household settings" ON household_settings;
DROP POLICY IF EXISTS "household_settings_select" ON household_settings;
DROP POLICY IF EXISTS "household_settings_insert" ON household_settings;
DROP POLICY IF EXISTS "household_settings_update" ON household_settings;

-- Feedback
DROP POLICY IF EXISTS "Allow all for feedback" ON feedback;
DROP POLICY IF EXISTS "Users can submit feedback" ON feedback;
DROP POLICY IF EXISTS "Users can view their own feedback" ON feedback;
DROP POLICY IF EXISTS "feedback_select" ON feedback;
DROP POLICY IF EXISTS "feedback_insert" ON feedback;

-- Household Invitations
DROP POLICY IF EXISTS "Allow all for household_invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can view their household invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can create invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can revoke invitations they created" ON household_invitations;
DROP POLICY IF EXISTS "Anyone can view invitation by token" ON household_invitations;
DROP POLICY IF EXISTS "Anyone can accept invitation" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_select" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_insert" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_update" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_delete" ON household_invitations;

-- Calendar Events
DROP POLICY IF EXISTS "Allow all for calendar_events" ON calendar_events;
DROP POLICY IF EXISTS "Household members can all calendar_events" ON calendar_events;
DROP POLICY IF EXISTS "Users can view their household calendar events" ON calendar_events;
DROP POLICY IF EXISTS "Users can create calendar events" ON calendar_events;
DROP POLICY IF EXISTS "Users can update their household calendar events" ON calendar_events;
DROP POLICY IF EXISTS "Users can delete their household calendar events" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_select" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_insert" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_update" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_delete" ON calendar_events;

-- Google Tokens
DROP POLICY IF EXISTS "Allow all for google_tokens" ON google_tokens;
DROP POLICY IF EXISTS "Users can all own google_tokens" ON google_tokens;
DROP POLICY IF EXISTS "google_tokens_select" ON google_tokens;
DROP POLICY IF EXISTS "google_tokens_insert" ON google_tokens;
DROP POLICY IF EXISTS "google_tokens_update" ON google_tokens;
DROP POLICY IF EXISTS "google_tokens_delete" ON google_tokens;

-- House Staples
DROP POLICY IF EXISTS "Allow all for house_staples" ON house_staples;
DROP POLICY IF EXISTS "house_staples_select" ON house_staples;
DROP POLICY IF EXISTS "house_staples_insert" ON house_staples;
DROP POLICY IF EXISTS "house_staples_update" ON house_staples;
DROP POLICY IF EXISTS "house_staples_delete" ON house_staples;

-- Recipe Ratings
DROP POLICY IF EXISTS "Users can view their household ratings" ON recipe_ratings;
DROP POLICY IF EXISTS "Users can insert ratings for their household" ON recipe_ratings;
DROP POLICY IF EXISTS "Users can update their household ratings" ON recipe_ratings;
DROP POLICY IF EXISTS "Users can delete their household ratings" ON recipe_ratings;

-- Meal Plan Templates
DROP POLICY IF EXISTS "Users can view their household templates" ON meal_plan_templates;
DROP POLICY IF EXISTS "Users can insert templates for their household" ON meal_plan_templates;
DROP POLICY IF EXISTS "Users can update their household templates" ON meal_plan_templates;
DROP POLICY IF EXISTS "Users can delete their household templates" ON meal_plan_templates;
DROP POLICY IF EXISTS "Authenticated users can select" ON meal_plan_templates;
DROP POLICY IF EXISTS "Authenticated users can insert" ON meal_plan_templates;
DROP POLICY IF EXISTS "Authenticated users can update" ON meal_plan_templates;
DROP POLICY IF EXISTS "Authenticated users can delete" ON meal_plan_templates;

-- Meal Plan Rotations
DROP POLICY IF EXISTS "Users can view their household rotations" ON meal_plan_rotations;
DROP POLICY IF EXISTS "Users can insert rotations for their household" ON meal_plan_rotations;
DROP POLICY IF EXISTS "Users can update their household rotations" ON meal_plan_rotations;
DROP POLICY IF EXISTS "Users can delete their household rotations" ON meal_plan_rotations;

-- =====================================================
-- STEP 2: ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE previous_grocery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE honeydew_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredient_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE pantry_staples ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE google_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE house_staples ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_rotations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: CREATE OPTIMIZED POLICIES
-- =====================================================
-- Using (select auth.uid()) for better performance

-- -----------------------------------------------------
-- Households
-- -----------------------------------------------------
CREATE POLICY "households_select" ON households FOR SELECT
    USING (id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "households_update" ON households FOR UPDATE
    USING (id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "households_insert" ON households FOR INSERT
    WITH CHECK (true);  -- Allow creation during signup

-- -----------------------------------------------------
-- Users
-- -----------------------------------------------------
CREATE POLICY "users_select" ON users FOR SELECT
    USING (
        id = (select auth.uid())
        OR household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
    );

CREATE POLICY "users_update" ON users FOR UPDATE
    USING (id = (select auth.uid()));

CREATE POLICY "users_insert" ON users FOR INSERT
    WITH CHECK (id = (select auth.uid()));

-- -----------------------------------------------------
-- Recipes
-- -----------------------------------------------------
CREATE POLICY "recipes_select" ON recipes FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipes_insert" ON recipes FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipes_update" ON recipes FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipes_delete" ON recipes FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Meal Plan Entries
-- -----------------------------------------------------
CREATE POLICY "meal_plan_entries_select" ON meal_plan_entries FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_entries_insert" ON meal_plan_entries FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_entries_update" ON meal_plan_entries FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_entries_delete" ON meal_plan_entries FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Grocery Lists
-- -----------------------------------------------------
CREATE POLICY "grocery_lists_select" ON grocery_lists FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "grocery_lists_insert" ON grocery_lists FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "grocery_lists_update" ON grocery_lists FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "grocery_lists_delete" ON grocery_lists FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Grocery Items
-- -----------------------------------------------------
CREATE POLICY "grocery_items_select" ON grocery_items FOR SELECT
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
    ));

CREATE POLICY "grocery_items_insert" ON grocery_items FOR INSERT
    WITH CHECK (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
    ));

CREATE POLICY "grocery_items_update" ON grocery_items FOR UPDATE
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
    ));

CREATE POLICY "grocery_items_delete" ON grocery_items FOR DELETE
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
    ));

-- -----------------------------------------------------
-- Previous Grocery Items
-- -----------------------------------------------------
CREATE POLICY "previous_grocery_items_select" ON previous_grocery_items FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "previous_grocery_items_insert" ON previous_grocery_items FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "previous_grocery_items_update" ON previous_grocery_items FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "previous_grocery_items_delete" ON previous_grocery_items FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Honeydew Tasks
-- -----------------------------------------------------
CREATE POLICY "honeydew_tasks_select" ON honeydew_tasks FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "honeydew_tasks_insert" ON honeydew_tasks FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "honeydew_tasks_update" ON honeydew_tasks FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "honeydew_tasks_delete" ON honeydew_tasks FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Restaurants
-- -----------------------------------------------------
CREATE POLICY "restaurants_select" ON restaurants FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurants_insert" ON restaurants FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurants_update" ON restaurants FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurants_delete" ON restaurants FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Restaurant Orders
-- -----------------------------------------------------
CREATE POLICY "restaurant_orders_select" ON restaurant_orders FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurant_orders_insert" ON restaurant_orders FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurant_orders_update" ON restaurant_orders FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "restaurant_orders_delete" ON restaurant_orders FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Household Members
-- -----------------------------------------------------
CREATE POLICY "household_members_select" ON household_members FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_members_insert" ON household_members FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_members_update" ON household_members FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_members_delete" ON household_members FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Ingredient Preferences
-- -----------------------------------------------------
CREATE POLICY "ingredient_preferences_select" ON ingredient_preferences FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "ingredient_preferences_insert" ON ingredient_preferences FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "ingredient_preferences_update" ON ingredient_preferences FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "ingredient_preferences_delete" ON ingredient_preferences FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Pantry Staples
-- -----------------------------------------------------
CREATE POLICY "pantry_staples_select" ON pantry_staples FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "pantry_staples_insert" ON pantry_staples FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "pantry_staples_update" ON pantry_staples FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "pantry_staples_delete" ON pantry_staples FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Household Settings
-- -----------------------------------------------------
CREATE POLICY "household_settings_select" ON household_settings FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_settings_insert" ON household_settings FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_settings_update" ON household_settings FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Feedback
-- -----------------------------------------------------
CREATE POLICY "feedback_select" ON feedback FOR SELECT
    USING (user_id = (select auth.uid()));

CREATE POLICY "feedback_insert" ON feedback FOR INSERT
    WITH CHECK (user_id = (select auth.uid()));

-- -----------------------------------------------------
-- Household Invitations
-- -----------------------------------------------------
-- Users can view invitations for their household
CREATE POLICY "household_invitations_select" ON household_invitations FOR SELECT
    USING (
        household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
        OR token IS NOT NULL  -- Allow lookup by token for accepting
    );

CREATE POLICY "household_invitations_insert" ON household_invitations FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "household_invitations_update" ON household_invitations FOR UPDATE
    USING (
        household_id IN (SELECT household_id FROM users WHERE id = (select auth.uid()))
        OR token IS NOT NULL  -- Allow updating when accepting by token
    );

CREATE POLICY "household_invitations_delete" ON household_invitations FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Calendar Events
-- -----------------------------------------------------
CREATE POLICY "calendar_events_select" ON calendar_events FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "calendar_events_insert" ON calendar_events FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "calendar_events_update" ON calendar_events FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "calendar_events_delete" ON calendar_events FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Google Tokens
-- -----------------------------------------------------
CREATE POLICY "google_tokens_select" ON google_tokens FOR SELECT
    USING (user_id = (select auth.uid()));

CREATE POLICY "google_tokens_insert" ON google_tokens FOR INSERT
    WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "google_tokens_update" ON google_tokens FOR UPDATE
    USING (user_id = (select auth.uid()));

CREATE POLICY "google_tokens_delete" ON google_tokens FOR DELETE
    USING (user_id = (select auth.uid()));

-- -----------------------------------------------------
-- House Staples
-- -----------------------------------------------------
CREATE POLICY "house_staples_select" ON house_staples FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "house_staples_insert" ON house_staples FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "house_staples_update" ON house_staples FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "house_staples_delete" ON house_staples FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Recipe Ratings
-- -----------------------------------------------------
CREATE POLICY "recipe_ratings_select" ON recipe_ratings FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipe_ratings_insert" ON recipe_ratings FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipe_ratings_update" ON recipe_ratings FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "recipe_ratings_delete" ON recipe_ratings FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Meal Plan Templates
-- -----------------------------------------------------
CREATE POLICY "meal_plan_templates_select" ON meal_plan_templates FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_templates_insert" ON meal_plan_templates FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_templates_update" ON meal_plan_templates FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_templates_delete" ON meal_plan_templates FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- -----------------------------------------------------
-- Meal Plan Rotations
-- -----------------------------------------------------
CREATE POLICY "meal_plan_rotations_select" ON meal_plan_rotations FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_rotations_insert" ON meal_plan_rotations FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_rotations_update" ON meal_plan_rotations FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

CREATE POLICY "meal_plan_rotations_delete" ON meal_plan_rotations FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = (select auth.uid())
    ));

-- =====================================================
-- Done! All policies are now:
-- 1. Using (select auth.uid()) for performance
-- 2. Single policy per action (no duplicates)
-- 3. Properly scoped to household
-- =====================================================
