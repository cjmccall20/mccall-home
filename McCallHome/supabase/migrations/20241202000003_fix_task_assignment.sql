-- Fix task assignment to reference household_members instead of profiles

-- Drop existing FK constraint to profiles
ALTER TABLE honeydew_tasks DROP CONSTRAINT IF EXISTS honeydew_tasks_assigned_to_fkey;

-- Add new FK constraint to household_members
ALTER TABLE honeydew_tasks ADD CONSTRAINT honeydew_tasks_assigned_to_fkey
    FOREIGN KEY (assigned_to) REFERENCES household_members(id) ON DELETE SET NULL;

-- Clear any existing assigned_to values that don't exist in household_members
UPDATE honeydew_tasks
SET assigned_to = NULL
WHERE assigned_to IS NOT NULL
AND assigned_to NOT IN (SELECT id FROM household_members);
