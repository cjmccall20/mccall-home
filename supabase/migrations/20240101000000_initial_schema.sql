-- McCall Home - Initial Database Schema
-- Migration: 20240101000000_initial_schema.sql
-- Apply via Supabase MCP or Supabase Dashboard SQL Editor

-- ============================================
-- TABLES
-- ============================================

-- Households (simple 2-person scope)
CREATE TABLE IF NOT EXISTS households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'McCall Family',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  household_id UUID REFERENCES households(id),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  notification_times TEXT[] DEFAULT ARRAY['07:00', '18:00'],
  device_token TEXT, -- For APNs push notifications
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks (Honeydew List)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  due_time TIME,
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  assigned_to UUID REFERENCES users(id),
  created_by UUID REFERENCES users(id) NOT NULL,
  is_complete BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recipes
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) NOT NULL,
  title TEXT NOT NULL,
  source_url TEXT,
  source_type TEXT CHECK (source_type IN ('manual', 'url', 'pasted_text')) DEFAULT 'manual',
  base_servings INT DEFAULT 4,
  ingredients JSONB NOT NULL DEFAULT '[]',
  steps JSONB NOT NULL DEFAULT '[]',
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  prep_time INTERVAL,
  cook_time INTERVAL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meal Plan (one recipe per day)
CREATE TABLE IF NOT EXISTS meal_plan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) NOT NULL,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  servings_override INT, -- NULL means use recipe default
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(household_id, scheduled_date)
);

-- Grocery Lists (one per week)
CREATE TABLE IF NOT EXISTS grocery_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) NOT NULL,
  week_start DATE NOT NULL,
  is_current BOOLEAN DEFAULT TRUE,
  meal_plan_hash TEXT, -- To detect if meal plan changed
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grocery Items
CREATE TABLE IF NOT EXISTS grocery_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grocery_list_id UUID REFERENCES grocery_lists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity NUMERIC,
  unit TEXT,
  category TEXT CHECK (category IN ('verify_pantry', 'produce', 'dairy', 'meat', 'pantry', 'frozen', 'other')) DEFAULT 'other',
  is_checked BOOLEAN DEFAULT FALSE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pantry Staples (default items to verify)
CREATE TABLE IF NOT EXISTS pantry_staples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID REFERENCES households(id) NOT NULL,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'verify_pantry',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_tasks_household ON tasks(household_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_is_complete ON tasks(is_complete);

CREATE INDEX IF NOT EXISTS idx_recipes_household ON recipes(household_id);
CREATE INDEX IF NOT EXISTS idx_recipes_title ON recipes(title);

CREATE INDEX IF NOT EXISTS idx_meal_plan_household ON meal_plan(household_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_date ON meal_plan(scheduled_date);

CREATE INDEX IF NOT EXISTS idx_grocery_items_list ON grocery_items(grocery_list_id);
CREATE INDEX IF NOT EXISTS idx_grocery_items_category ON grocery_items(category);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to create default pantry staples for a new household
CREATE OR REPLACE FUNCTION create_default_staples(p_household_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO pantry_staples (household_id, name) VALUES
    (p_household_id, 'Salt'),
    (p_household_id, 'Pepper'),
    (p_household_id, 'Olive Oil'),
    (p_household_id, 'Butter'),
    (p_household_id, 'Garlic'),
    (p_household_id, 'Onions'),
    (p_household_id, 'All-Purpose Flour'),
    (p_household_id, 'Sugar'),
    (p_household_id, 'Vegetable Oil'),
    (p_household_id, 'Chicken Broth'),
    (p_household_id, 'Rice'),
    (p_household_id, 'Pasta');
END;
$$ LANGUAGE plpgsql;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_recipes_updated_at ON recipes;
CREATE TRIGGER update_recipes_updated_at
  BEFORE UPDATE ON recipes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE pantry_staples ENABLE ROW LEVEL SECURITY;

-- Users can only see their own user record
CREATE POLICY "Users can view own record" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own record" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Household members can access their household
CREATE POLICY "Household members can view household" ON households
  FOR SELECT USING (
    id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- Household members can access their household's tasks
CREATE POLICY "Household members can view tasks" ON tasks
  FOR SELECT USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can insert tasks" ON tasks
  FOR INSERT WITH CHECK (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can update tasks" ON tasks
  FOR UPDATE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can delete tasks" ON tasks
  FOR DELETE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- Household members can access their household's recipes
CREATE POLICY "Household members can view recipes" ON recipes
  FOR SELECT USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can insert recipes" ON recipes
  FOR INSERT WITH CHECK (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can update recipes" ON recipes
  FOR UPDATE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can delete recipes" ON recipes
  FOR DELETE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- Meal Plan policies
CREATE POLICY "Household members can view meal_plan" ON meal_plan
  FOR SELECT USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can insert meal_plan" ON meal_plan
  FOR INSERT WITH CHECK (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can update meal_plan" ON meal_plan
  FOR UPDATE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can delete meal_plan" ON meal_plan
  FOR DELETE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- Grocery List policies
CREATE POLICY "Household members can view grocery_lists" ON grocery_lists
  FOR SELECT USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can insert grocery_lists" ON grocery_lists
  FOR INSERT WITH CHECK (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can update grocery_lists" ON grocery_lists
  FOR UPDATE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can delete grocery_lists" ON grocery_lists
  FOR DELETE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- Grocery Items policies (via grocery_list ownership)
CREATE POLICY "Household members can view grocery_items" ON grocery_items
  FOR SELECT USING (
    grocery_list_id IN (
      SELECT gl.id FROM grocery_lists gl
      WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Household members can insert grocery_items" ON grocery_items
  FOR INSERT WITH CHECK (
    grocery_list_id IN (
      SELECT gl.id FROM grocery_lists gl
      WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Household members can update grocery_items" ON grocery_items
  FOR UPDATE USING (
    grocery_list_id IN (
      SELECT gl.id FROM grocery_lists gl
      WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Household members can delete grocery_items" ON grocery_items
  FOR DELETE USING (
    grocery_list_id IN (
      SELECT gl.id FROM grocery_lists gl
      WHERE gl.household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
    )
  );

-- Pantry Staples policies
CREATE POLICY "Household members can view pantry_staples" ON pantry_staples
  FOR SELECT USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can insert pantry_staples" ON pantry_staples
  FOR INSERT WITH CHECK (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can update pantry_staples" ON pantry_staples
  FOR UPDATE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Household members can delete pantry_staples" ON pantry_staples
  FOR DELETE USING (
    household_id IN (SELECT household_id FROM users WHERE id = auth.uid())
  );

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE households IS 'Family units - each user belongs to one household';
COMMENT ON TABLE users IS 'App users linked to Supabase Auth';
COMMENT ON TABLE tasks IS 'Honeydew list items - tasks assigned between household members';
COMMENT ON TABLE recipes IS 'Recipe database with ingredients and steps stored as JSONB';
COMMENT ON TABLE meal_plan IS 'Weekly dinner assignments - one recipe per day';
COMMENT ON TABLE grocery_lists IS 'Generated shopping lists, one per week';
COMMENT ON TABLE grocery_items IS 'Individual items on a grocery list';
COMMENT ON TABLE pantry_staples IS 'Default items to verify before shopping';

COMMENT ON COLUMN recipes.ingredients IS 'JSON array: [{name, quantity, unit, category}]';
COMMENT ON COLUMN recipes.steps IS 'JSON array: [{step, instruction}]';
COMMENT ON COLUMN meal_plan.servings_override IS 'NULL means use recipe base_servings';
COMMENT ON COLUMN grocery_lists.meal_plan_hash IS 'Hash of meal plan to detect changes';
