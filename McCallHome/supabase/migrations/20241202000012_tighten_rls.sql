-- =====================================================
-- Tighten RLS Policies
-- =====================================================
-- Replace permissive "allow all" policies with proper
-- household-based access control

-- Note: During development, some tables had permissive policies.
-- This migration tightens them for production readiness.

-- =====================================================
-- Households
-- =====================================================
DROP POLICY IF EXISTS "Allow all for households" ON households;

CREATE POLICY "Users can view their household"
    ON households FOR SELECT
    USING (id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household"
    ON households FOR UPDATE
    USING (id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Users
-- =====================================================
DROP POLICY IF EXISTS "Allow all for users" ON users;

CREATE POLICY "Users can view users in their household"
    ON users FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- =====================================================
-- Recipes
-- =====================================================
DROP POLICY IF EXISTS "Allow all for recipes" ON recipes;

CREATE POLICY "Users can view their household recipes"
    ON recipes FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create recipes for their household"
    ON recipes FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household recipes"
    ON recipes FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household recipes"
    ON recipes FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Meal Plan Entries
-- =====================================================
DROP POLICY IF EXISTS "Allow all for meal_plan_entries" ON meal_plan_entries;

CREATE POLICY "Users can view their household meal plan"
    ON meal_plan_entries FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create meal plan entries"
    ON meal_plan_entries FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household meal plan"
    ON meal_plan_entries FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household meal plan entries"
    ON meal_plan_entries FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Grocery Lists
-- =====================================================
DROP POLICY IF EXISTS "Allow all for grocery_lists" ON grocery_lists;

CREATE POLICY "Users can view their household grocery lists"
    ON grocery_lists FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create grocery lists"
    ON grocery_lists FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household grocery lists"
    ON grocery_lists FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household grocery lists"
    ON grocery_lists FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Grocery Items
-- =====================================================
DROP POLICY IF EXISTS "Allow all for grocery_items" ON grocery_items;

CREATE POLICY "Users can view their household grocery items"
    ON grocery_items FOR SELECT
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        JOIN users u ON u.household_id = gl.household_id
        WHERE u.id = auth.uid()
    ));

CREATE POLICY "Users can create grocery items"
    ON grocery_items FOR INSERT
    WITH CHECK (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        JOIN users u ON u.household_id = gl.household_id
        WHERE u.id = auth.uid()
    ));

CREATE POLICY "Users can update their household grocery items"
    ON grocery_items FOR UPDATE
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        JOIN users u ON u.household_id = gl.household_id
        WHERE u.id = auth.uid()
    ));

CREATE POLICY "Users can delete their household grocery items"
    ON grocery_items FOR DELETE
    USING (grocery_list_id IN (
        SELECT gl.id FROM grocery_lists gl
        JOIN users u ON u.household_id = gl.household_id
        WHERE u.id = auth.uid()
    ));

-- =====================================================
-- Honeydew Tasks
-- =====================================================
DROP POLICY IF EXISTS "Allow all for honeydew_tasks" ON honeydew_tasks;

CREATE POLICY "Users can view their household tasks"
    ON honeydew_tasks FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create tasks for their household"
    ON honeydew_tasks FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household tasks"
    ON honeydew_tasks FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household tasks"
    ON honeydew_tasks FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Restaurants
-- =====================================================
DROP POLICY IF EXISTS "Allow all for restaurants" ON restaurants;

CREATE POLICY "Users can view their household restaurants"
    ON restaurants FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create restaurants for their household"
    ON restaurants FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household restaurants"
    ON restaurants FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household restaurants"
    ON restaurants FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Restaurant Orders
-- =====================================================
DROP POLICY IF EXISTS "Allow all for restaurant_orders" ON restaurant_orders;

CREATE POLICY "Users can view their household restaurant orders"
    ON restaurant_orders FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create restaurant orders"
    ON restaurant_orders FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household restaurant orders"
    ON restaurant_orders FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household restaurant orders"
    ON restaurant_orders FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Ingredient Preferences
-- =====================================================
DROP POLICY IF EXISTS "Allow all for ingredient_preferences" ON ingredient_preferences;

CREATE POLICY "Users can view their household ingredient preferences"
    ON ingredient_preferences FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create ingredient preferences"
    ON ingredient_preferences FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household ingredient preferences"
    ON ingredient_preferences FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household ingredient preferences"
    ON ingredient_preferences FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- =====================================================
-- Pantry Staples
-- =====================================================
DROP POLICY IF EXISTS "Allow all for pantry_staples" ON pantry_staples;

CREATE POLICY "Users can view their household pantry staples"
    ON pantry_staples FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can create pantry staples"
    ON pantry_staples FOR INSERT
    WITH CHECK (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can update their household pantry staples"
    ON pantry_staples FOR UPDATE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

CREATE POLICY "Users can delete their household pantry staples"
    ON pantry_staples FOR DELETE
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));
