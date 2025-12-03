-- Fix RLS policy for honeydew_tasks to allow dev mode access
-- While still maintaining household-level isolation

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can create tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can update tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_select" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_insert" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_update" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_delete" ON honeydew_tasks;

-- For development: allow all operations (will tighten for production)
-- These policies allow access when either:
-- 1. User is authenticated and belongs to the household, OR
-- 2. Using the dev household ID (for simulator testing)

CREATE POLICY "honeydew_tasks_select" ON honeydew_tasks
    FOR SELECT USING (
        household_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "honeydew_tasks_insert" ON honeydew_tasks
    FOR INSERT WITH CHECK (
        household_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "honeydew_tasks_update" ON honeydew_tasks
    FOR UPDATE USING (
        household_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );

CREATE POLICY "honeydew_tasks_delete" ON honeydew_tasks
    FOR DELETE USING (
        household_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
    );
