-- =====================================================
-- Fix Constraints and Add Features Migration
-- =====================================================

-- 0. Add dish_category column to recipes table
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS dish_category TEXT DEFAULT 'entree';

-- 1. Drop and recreate grocery_items category check constraint
-- to include all app-defined categories
ALTER TABLE grocery_items DROP CONSTRAINT IF EXISTS grocery_items_category_check;

-- Add updated check constraint with all valid categories
ALTER TABLE grocery_items ADD CONSTRAINT grocery_items_category_check
    CHECK (category IN ('verify_pantry', 'produce', 'dairy', 'meat', 'bakery', 'pantry', 'frozen', 'beverages', 'other'));

-- 2. Make created_by nullable in honeydew_tasks (for dev mode)
-- First drop the FK constraint if it exists
ALTER TABLE honeydew_tasks DROP CONSTRAINT IF EXISTS honeydew_tasks_created_by_fkey;
ALTER TABLE honeydew_tasks DROP CONSTRAINT IF EXISTS tasks_created_by_fkey;

-- Alter column to allow NULL
ALTER TABLE honeydew_tasks ALTER COLUMN created_by DROP NOT NULL;

-- Re-add FK constraint but allowing NULL values
ALTER TABLE honeydew_tasks ADD CONSTRAINT honeydew_tasks_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- 3. Make assigned_to nullable as well (should already be, but ensure it)
ALTER TABLE honeydew_tasks DROP CONSTRAINT IF EXISTS honeydew_tasks_assigned_to_fkey;
ALTER TABLE honeydew_tasks ALTER COLUMN assigned_to DROP NOT NULL;
ALTER TABLE honeydew_tasks ADD CONSTRAINT honeydew_tasks_assigned_to_fkey
    FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;

-- 4. Ensure profiles table doesn't require auth.users FK for dev mode
-- Create profiles without the FK constraint (for dev testing)
-- Note: This is a workaround; in production, you'd use proper auth

-- Add Row Level Security policies that allow dev mode operations
-- First, enable RLS if not enabled
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE honeydew_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;

-- Create permissive policies for development (allow all operations with anon key)
-- These should be tightened for production

-- Households policies
DROP POLICY IF EXISTS "Allow all for households" ON households;
CREATE POLICY "Allow all for households" ON households FOR ALL USING (true) WITH CHECK (true);

-- Profiles policies
DROP POLICY IF EXISTS "Allow all for profiles" ON profiles;
CREATE POLICY "Allow all for profiles" ON profiles FOR ALL USING (true) WITH CHECK (true);

-- Recipes policies
DROP POLICY IF EXISTS "Allow all for recipes" ON recipes;
CREATE POLICY "Allow all for recipes" ON recipes FOR ALL USING (true) WITH CHECK (true);

-- Meal plan entries policies
DROP POLICY IF EXISTS "Allow all for meal_plan_entries" ON meal_plan_entries;
CREATE POLICY "Allow all for meal_plan_entries" ON meal_plan_entries FOR ALL USING (true) WITH CHECK (true);

-- Honeydew tasks policies
DROP POLICY IF EXISTS "Allow all for honeydew_tasks" ON honeydew_tasks;
CREATE POLICY "Allow all for honeydew_tasks" ON honeydew_tasks FOR ALL USING (true) WITH CHECK (true);

-- Grocery lists policies
DROP POLICY IF EXISTS "Allow all for grocery_lists" ON grocery_lists;
CREATE POLICY "Allow all for grocery_lists" ON grocery_lists FOR ALL USING (true) WITH CHECK (true);

-- Grocery items policies
DROP POLICY IF EXISTS "Allow all for grocery_items" ON grocery_items;
CREATE POLICY "Allow all for grocery_items" ON grocery_items FOR ALL USING (true) WITH CHECK (true);

-- Previous grocery items policies
DROP POLICY IF EXISTS "Allow all for previous_grocery_items" ON previous_grocery_items;
CREATE POLICY "Allow all for previous_grocery_items" ON previous_grocery_items FOR ALL USING (true) WITH CHECK (true);
