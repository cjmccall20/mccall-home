-- =====================================================
-- Phase 4 Features Migration
-- =====================================================
-- Adds: meal plan templates, rotations, recipe ratings,
-- household settings updates, and meal entry improvements

-- =====================================================
-- 1. Household Settings Updates
-- =====================================================
-- Add new settings columns for week start, grocery prep day, and dark mode

ALTER TABLE household_settings ADD COLUMN IF NOT EXISTS week_start_day INTEGER DEFAULT 0;  -- 0=Sunday, 1=Monday, etc.
ALTER TABLE household_settings ADD COLUMN IF NOT EXISTS grocery_prep_day INTEGER DEFAULT 6; -- 6=Saturday
ALTER TABLE household_settings ADD COLUMN IF NOT EXISTS dark_mode TEXT DEFAULT 'system';    -- 'system', 'light', 'dark'

-- =====================================================
-- 2. Meal Plan Entry Updates
-- =====================================================
-- Add has_ingredients flag to skip generating grocery items

ALTER TABLE meal_plan_entries ADD COLUMN IF NOT EXISTS has_ingredients BOOLEAN DEFAULT FALSE;

-- =====================================================
-- 3. Meal Plan Templates Table
-- =====================================================
-- Stores saved week templates for quick meal planning

CREATE TABLE IF NOT EXISTS meal_plan_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    entries JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Array of TemplateEntry objects
    is_rotating BOOLEAN DEFAULT FALSE,  -- If true, part of a rotation schedule
    rotation_order INTEGER,  -- Order in the rotation (1, 2, 3, etc.)
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- If table exists but missing columns, add them
ALTER TABLE meal_plan_templates ADD COLUMN IF NOT EXISTS is_rotating BOOLEAN DEFAULT FALSE;
ALTER TABLE meal_plan_templates ADD COLUMN IF NOT EXISTS rotation_order INTEGER;
ALTER TABLE meal_plan_templates ADD COLUMN IF NOT EXISTS notes TEXT;

-- Index for fast lookups by household
CREATE INDEX IF NOT EXISTS idx_meal_plan_templates_household ON meal_plan_templates(household_id);

-- Enable RLS
ALTER TABLE meal_plan_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for meal_plan_templates
DO $$ BEGIN
    CREATE POLICY "Users can view their household templates"
        ON meal_plan_templates FOR SELECT
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can insert templates for their household"
        ON meal_plan_templates FOR INSERT
        WITH CHECK (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their household templates"
        ON meal_plan_templates FOR UPDATE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their household templates"
        ON meal_plan_templates FOR DELETE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- 4. Meal Plan Rotations Table
-- =====================================================
-- Stores rotating meal schedules

CREATE TABLE IF NOT EXISTS meal_plan_rotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    template_ids JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Array of template UUIDs in rotation order
    current_index INTEGER DEFAULT 0,  -- Which template is currently active
    start_date DATE,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- If table exists but missing columns, add them
ALTER TABLE meal_plan_rotations ADD COLUMN IF NOT EXISTS template_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE meal_plan_rotations ADD COLUMN IF NOT EXISTS current_index INTEGER DEFAULT 0;

-- Index for fast lookups by household
CREATE INDEX IF NOT EXISTS idx_meal_plan_rotations_household ON meal_plan_rotations(household_id);

-- Enable RLS
ALTER TABLE meal_plan_rotations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for meal_plan_rotations
DO $$ BEGIN
    CREATE POLICY "Users can view their household rotations"
        ON meal_plan_rotations FOR SELECT
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can insert rotations for their household"
        ON meal_plan_rotations FOR INSERT
        WITH CHECK (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their household rotations"
        ON meal_plan_rotations FOR UPDATE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their household rotations"
        ON meal_plan_rotations FOR DELETE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- 5. Recipe Ratings Table
-- =====================================================
-- Per-member ratings and favorites for recipes

CREATE TABLE IF NOT EXISTS recipe_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES household_members(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),  -- 1-5 stars, null if not rated
    is_favorite BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(household_id, member_id, recipe_id)  -- One rating per member per recipe
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_household ON recipe_ratings(household_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_member ON recipe_ratings(member_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_recipe ON recipe_ratings(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_favorite ON recipe_ratings(is_favorite) WHERE is_favorite = true;

-- Enable RLS
ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for recipe_ratings
DO $$ BEGIN
    CREATE POLICY "Users can view their household ratings"
        ON recipe_ratings FOR SELECT
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can insert ratings for their household"
        ON recipe_ratings FOR INSERT
        WITH CHECK (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their household ratings"
        ON recipe_ratings FOR UPDATE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their household ratings"
        ON recipe_ratings FOR DELETE
        USING (household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        ));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- 6. Ingredient Preferences Updates
-- =====================================================
-- Add brand field for Instacart specificity

ALTER TABLE ingredient_preferences ADD COLUMN IF NOT EXISTS brand TEXT;

-- =====================================================
-- 7. Grocery List Updates
-- =====================================================
-- Add generation info to grocery lists

ALTER TABLE grocery_lists ADD COLUMN IF NOT EXISTS date_range_start DATE;
ALTER TABLE grocery_lists ADD COLUMN IF NOT EXISTS date_range_end DATE;

-- =====================================================
-- 8. Updated At Triggers
-- =====================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for meal_plan_templates
DROP TRIGGER IF EXISTS update_meal_plan_templates_updated_at ON meal_plan_templates;
CREATE TRIGGER update_meal_plan_templates_updated_at
    BEFORE UPDATE ON meal_plan_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for meal_plan_rotations
DROP TRIGGER IF EXISTS update_meal_plan_rotations_updated_at ON meal_plan_rotations;
CREATE TRIGGER update_meal_plan_rotations_updated_at
    BEFORE UPDATE ON meal_plan_rotations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for recipe_ratings
DROP TRIGGER IF EXISTS update_recipe_ratings_updated_at ON recipe_ratings;
CREATE TRIGGER update_recipe_ratings_updated_at
    BEFORE UPDATE ON recipe_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
