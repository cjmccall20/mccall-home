-- =====================================================
-- McCallHome Complete Schema Setup
-- =====================================================

-- 1. Households table
CREATE TABLE IF NOT EXISTS households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Users/Profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id),
    display_name TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Recipes table
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    source_url TEXT,
    source_type TEXT DEFAULT 'manual',
    protein_type TEXT DEFAULT 'other',
    base_servings INTEGER DEFAULT 4,
    ingredients JSONB DEFAULT '[]'::jsonb,
    steps JSONB DEFAULT '[]'::jsonb,
    tags TEXT[],
    prep_time INTEGER,
    cook_time INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add protein_type if table existed without it
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS protein_type TEXT DEFAULT 'other';

-- 4. Meal Plan Entries table
CREATE TABLE IF NOT EXISTS meal_plan_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    meal_type TEXT DEFAULT 'dinner',
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    is_eat_out BOOLEAN DEFAULT FALSE,
    eat_out_location TEXT,
    servings_override INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add new columns if table existed
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS meal_type TEXT DEFAULT 'dinner';
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS is_eat_out BOOLEAN DEFAULT FALSE;
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS eat_out_location TEXT;
ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS servings_override INTEGER;

-- 5. Honeydew Tasks table
CREATE TABLE IF NOT EXISTS honeydew_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    due_date DATE,
    due_time TEXT,
    priority TEXT DEFAULT 'medium',
    assigned_to UUID REFERENCES profiles(id),
    created_by UUID REFERENCES profiles(id),
    is_complete BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    recurrence_rule JSONB,
    reminder_minutes_before INTEGER,
    next_occurrence TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add new columns if table existed
ALTER TABLE honeydew_tasks ADD COLUMN IF NOT EXISTS due_time TEXT;
ALTER TABLE honeydew_tasks ADD COLUMN IF NOT EXISTS recurrence_rule JSONB;
ALTER TABLE honeydew_tasks ADD COLUMN IF NOT EXISTS reminder_minutes_before INTEGER;
ALTER TABLE honeydew_tasks ADD COLUMN IF NOT EXISTS next_occurrence TIMESTAMPTZ;

-- 6. Grocery Lists table
CREATE TABLE IF NOT EXISTS grocery_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    week_start DATE,
    is_current BOOLEAN DEFAULT TRUE,
    meal_plan_hash TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Grocery Items table
CREATE TABLE IF NOT EXISTS grocery_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grocery_list_id UUID NOT NULL REFERENCES grocery_lists(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity DOUBLE PRECISION,
    unit TEXT,
    category TEXT DEFAULT 'other',
    is_checked BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    source TEXT DEFAULT 'manual',
    from_recipe_id UUID REFERENCES recipes(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add new columns if table existed
ALTER TABLE grocery_items ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE grocery_items ADD COLUMN IF NOT EXISTS from_recipe_id UUID REFERENCES recipes(id);

-- 8. Previous Grocery Items table (for quick re-add)
CREATE TABLE IF NOT EXISTS previous_grocery_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT DEFAULT 'other',
    times_used INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(household_id, name)
);

-- 9. Indexes
CREATE INDEX IF NOT EXISTS idx_recipes_household ON recipes(household_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_household ON meal_plan_entries(household_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_date ON meal_plan_entries(date);
CREATE INDEX IF NOT EXISTS idx_honeydew_tasks_household ON honeydew_tasks(household_id);
CREATE INDEX IF NOT EXISTS idx_honeydew_tasks_due_date ON honeydew_tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_household ON grocery_lists(household_id);
CREATE INDEX IF NOT EXISTS idx_grocery_items_list ON grocery_items(grocery_list_id);
CREATE INDEX IF NOT EXISTS idx_previous_grocery_items_household ON previous_grocery_items(household_id);
CREATE INDEX IF NOT EXISTS idx_profiles_household ON profiles(household_id);

-- 10. Unique constraint for meal plan (one entry per household/date/meal_type)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'meal_plan_entries_household_date_meal_unique'
    ) THEN
        ALTER TABLE meal_plan_entries ADD CONSTRAINT meal_plan_entries_household_date_meal_unique
            UNIQUE (household_id, date, meal_type);
    END IF;
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;
