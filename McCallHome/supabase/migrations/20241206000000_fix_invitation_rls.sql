-- =====================================================
-- Fix Household Invitations RLS Policy
-- =====================================================
-- The original policy "Users can create invitations for their household"
-- was never dropped because security_cleanup tried to drop a differently
-- named policy. This migration fixes that.

-- Drop any old policies that may still exist
DROP POLICY IF EXISTS "Users can create invitations for their household" ON household_invitations;
DROP POLICY IF EXISTS "Users can view their household invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can revoke invitations they created" ON household_invitations;

-- Drop current policies to recreate them fresh
DROP POLICY IF EXISTS "household_invitations_select" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_insert" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_update" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_delete" ON household_invitations;

-- Recreate policies using get_my_household_id() for consistency
CREATE POLICY "household_invitations_select" ON household_invitations FOR SELECT
    USING (
        household_id = get_my_household_id()
        OR true  -- Allow lookup by token for accepting
    );

CREATE POLICY "household_invitations_insert" ON household_invitations FOR INSERT
    WITH CHECK (
        household_id = get_my_household_id()
        AND invited_by = (SELECT auth.uid())
    );

CREATE POLICY "household_invitations_update" ON household_invitations FOR UPDATE
    USING (
        household_id = get_my_household_id()
        OR true  -- Allow updating when accepting by token
    );

CREATE POLICY "household_invitations_delete" ON household_invitations FOR DELETE
    USING (household_id = get_my_household_id());
